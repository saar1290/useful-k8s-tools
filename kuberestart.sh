#! /bin/bash

RED="\e[91m"
GREEN="\e[92m"
BLUE="\e[94m"
PURPLE="\e[95m"
YELLOW="\e[93m"
NONE="\e[0m"

patch_ops(){        
    # This function is modifying the configuration of the Kured deamonset,
    ## and craeting new pods with a new configuration, then monitoring the process on screen, 
    ## and finally rolling back to the old configuration
    
    # Storing the original config in temporary files, and set vars for files
    kubectl get -n kured ds kured -o json | jq '.spec.template.spec.containers[0].args[3]' > /tmp/end-time-org.txt
    kubectl get -n kured ds kured -o json | jq '.spec.template.spec.containers[0].args[8]' > /tmp/start-time-org.txt
    kubectl get -n kured ds kured -o json | jq '.spec.template.spec.containers[0].args[5]' > /tmp/reboot-days-org.txt
    end_time_org=$(cat /tmp/end-time-org.txt | tr -d '"' | cut -d = -f2)
    start_time_org=$(cat /tmp/start-time-org.txt | tr -d '"' | cut -d = -f2)
    reboot_days_org=$(cat /tmp/reboot-days-org.txt | tr -d '"' | cut -d = -f2)

    # Patching the schedule on current day, start in 2 min and end in 10 min
    start_time=$(date -d '+2 minute' +%R)
    end_time=$(date -d '+10 minute' +%R)
    reboot_days=$(date +%a | tr '[:upper:]' '[:lower:]')
    ## end-time
    kubectl get ds kured -n kured -o json | jq '.spec.template.spec.containers[0].args[3] = "--end-time='$end_time'"' | kubectl replace -f -
    ## start-time
    kubectl get ds kured -n kured -o json | jq '.spec.template.spec.containers[0].args[8] = "--start-time='$start_time'"' | kubectl replace -f -
    ## reboot-days
    kubectl get ds kured -n kured -o json | jq '.spec.template.spec.containers[0].args[5] = "reboot-days='$reboot_days'"' | kubectl replace -f - 
    
    sleep 2
    echo -e $GREEN"*** The monitoring screen on nodes will show up in a few seconds, and will allow you to take a look at which node is in the restart progress ***$NONE
${RED}Note that when you'll exit from the monitoring screen the original configuration will take effect!"$NONE
    for s in {1..15};do sleep 1 && echo -ne $BLUE"$s "$NONE;done
    watch -n 0.1 -d kubectl get node
    # Revert the changes to original configuration
    ## end-time-original
    kubectl get ds kured -n kured -o json | jq '.spec.template.spec.containers[0].args[3] = "--end-time='$end_time_org'"' | kubectl replace -f -
    ## start-time-original
    kubectl get ds kured -n kured -o json | jq '.spec.template.spec.containers[0].args[8] = "--start-time='$start_time_org'"' | kubectl replace -f -
    ## reboot-days-original
    kubectl get ds kured -n kured -o json | jq '.spec.template.spec.containers[0].args[5] = "reboot-days='$reboot_days_org'"' | kubectl replace -f -
    # Print the original configuration
    echo -e $YELLOW"The original configuration set successfully"$NONE
    sleep 3
    kubectl get ds kured -n kured -o json | jq '.spec.template.spec.containers[0].args'
    rm -f /tmp/end-time-org.txt /tmp/start-time-org.txt /tmp/reboot-days-org.txt
}

restart_all(){
    while true; do
        echo -ne $YELLOW"Would you like to create a reboot-required file on nodes? "$NONE; read answer
        if [[ $answer == "yes" ]]; then
            nodes=$(kubectl get node | awk '{print $1}' | awk '(NR>1)')
            echo -e $BLUE"Enter your password --> "$NONE ; read -s pass
            for n in $nodes; do
                sshpass -p $pass ssh -t $n "sudo touch /var/run/reboot-required && ls -al /var/run/reboot-required"
                if [ $? == "0" ]; then
                    echo -e $GREEN"*** Node $n is ready to restart and waiting for daemonset to trigger it by schedule ***"$NONE
                else
                    echo -e $RED"For some reason node $n is not ready for restart. Kured can't take affect on node $n.\n
                    Please try again or debug it manually, by creating file /var/run/reboot-required into node $n..."$NONE
                    break
                fi
            done
            patch_ops
            break
        elif [[ $answer == "no" ]]; then
            patch_ops
            break
        else
            echo -e $RED"Please answer yes/no"$NONE
        fi
    done
}

restart_specific(){
    while true; do
        echo -ne $YELLOW"Would you like to create a reboot-required file on nodes? "$NONE; read answer
        if [[ $answer == "yes" ]]; then
            nodes=$(kubectl get node | awk '{print $1}' | awk '(NR>1)')
            nodes_list=()
            index=1
            for n in $nodes; do
                echo -e $PURPLE"$index)"$NONE $BLUE"$n \n"$NONE
                let index=${index}+1
                nodes_list+=($n)
            done
            while true; do
                echo -ne $PURPLE"Choose a node to take control of, by a number ---> "$NONE; read node
                if [[ $node == ?(-)+([0-9]) ]]; then
                    node=${nodes_list[$node -1]}
                    break
                else
                    echo -e $RED"Choises such as letters are not accepted!"$NONE
                fi
            done
            echo -e $GREEN"*** The captain (kubectl) takes control of the node $node ***"$NONE
            echo -e $BLUE"Enter your password -->"$NONE ; read -s pass
            sshpass -p $pass ssh -t $node "sudo touch /var/run/reboot-required && ls -al /var/run/reboot-required"
            if [ $? == "0" ]; then
                echo -e $GREEN"*** Node $node is ready to restart and waiting for daemonset to trigger it by schedule ***"$NONE
                sleep 2
            else
                echo -e $RED"For some reason node $node is not ready for restart. Kured can't take affect on node $node.\n
                Please try again or debug it manually, by creating file /var/run/reboot-required into node $node..."$NONE
                sleep 2
            fi
            patch_ops
            break
        elif [[ $answer == "no" ]]; then
            patch_ops
            break
        else
            echo -e $RED"Please answer yes/no"$NONE
        fi
    done
}

clusters=$(kubectl config get-contexts | awk '{print $2}' | awk '(NR>1)')
clusters_list=()
index=1
for c in $clusters; do 
    echo -e $YELLOW"$index)$NONE $c\n"
    let index=${index}+1
    clusters_list+=($c)
done

while true; do
    echo -ne $PURPLE"Choose a cluster to take control of, by a number ---> "$NONE; read cluster
    if [[ $cluster == ?(-)+([0-9]) ]]; then
        cluster=${clusters_list[$cluster -1]}
        break
    else
        echo -e $RED"Choises such as letters are not accepted!"$NONE
    fi
done

echo -e $GREEN"*** The captain (kubectl) takes control of the cluster $cluster ***"$NONE
kubectl config use-context $cluster

echo -ne $PURPLE"
Operations for cluster $cluster:$NONE

"$BLUE"1) Perform restart on all nodes\n
2) Perform restart on specific node$NONE

"$YELLOW"Select an operation: "$NONE

read operation
echo ""
case $operation in
    1) 
        restart_all ;;
    2) 
        restart_specific ;;
    *)
        echo -e $RED"Wrong option, please try again"$NONE
        exit ;;
esac