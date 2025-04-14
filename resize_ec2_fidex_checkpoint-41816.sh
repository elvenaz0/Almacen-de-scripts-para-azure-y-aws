#!/bin/bash
# Script para resize de instancias EC2 con Elastic IP conservada
# Con checkpoints por instancia para continuar desde donde se quedó

LOG_FILE=resize_ec2_checkpoints.log
CHECKPOINT_FILE=.resize_checkpoints

touch $CHECKPOINT_FILE
echo "--- Inicio de ejecución: $(date) ---" >> $LOG_FILE

# Revisar si ya se procesó FidexAppsProd2
if grep -q "^FidexAppsProd2$" $CHECKPOINT_FILE; then
    echo '⏩ FidexAppsProd2 ya fue procesada, omitiendo...' | tee -a $LOG_FILE
    continue
fi

echo '--- Procesando FidexAppsProd2 ---' | tee -a $LOG_FILE
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=FidexAppsProd2" --query "Reservations[].Instances[].InstanceId" --output text)
if [ -z "$INSTANCE_ID" ]; then echo '❌ No se encontró FidexAppsProd2' | tee -a $LOG_FILE; exit 1; fi
aws ec2 stop-instances --instance-ids $INSTANCE_ID | tee -a $LOG_FILE
aws ec2 wait instance-stopped --instance-ids $INSTANCE_ID
aws ec2 modify-instance-attribute --instance-id $INSTANCE_ID --instance-type '{"Value":"t3.micro"}' | tee -a $LOG_FILE
aws ec2 start-instances --instance-ids $INSTANCE_ID | tee -a $LOG_FILE
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
echo '✅ FidexAppsProd2 redimensionada a t3.micro' | tee -a $LOG_FILE
echo "FidexAppsProd2" >> $CHECKPOINT_FILE

# Revisar si ya se procesó FidexAppsProd3
if grep -q "^FidexAppsProd3$" $CHECKPOINT_FILE; then
    echo '⏩ FidexAppsProd3 ya fue procesada, omitiendo...' | tee -a $LOG_FILE
    continue
fi

echo '--- Procesando FidexAppsProd3 ---' | tee -a $LOG_FILE
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=FidexAppsProd3" --query "Reservations[].Instances[].InstanceId" --output text)
if [ -z "$INSTANCE_ID" ]; then echo '❌ No se encontró FidexAppsProd3' | tee -a $LOG_FILE; exit 1; fi
aws ec2 stop-instances --instance-ids $INSTANCE_ID | tee -a $LOG_FILE
aws ec2 wait instance-stopped --instance-ids $INSTANCE_ID
aws ec2 modify-instance-attribute --instance-id $INSTANCE_ID --instance-type '{"Value":"t3.small"}' | tee -a $LOG_FILE
aws ec2 start-instances --instance-ids $INSTANCE_ID | tee -a $LOG_FILE
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
echo '✅ FidexAppsProd3 redimensionada a t3.small' | tee -a $LOG_FILE
echo "FidexAppsProd3" >> $CHECKPOINT_FILE

# Revisar si ya se procesó FidexAppsProd4
if grep -q "^FidexAppsProd4$" $CHECKPOINT_FILE; then
    echo '⏩ FidexAppsProd4 ya fue procesada, omitiendo...' | tee -a $LOG_FILE
    continue
fi

echo '--- Procesando FidexAppsProd4 ---' | tee -a $LOG_FILE
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=FidexAppsProd4" --query "Reservations[].Instances[].InstanceId" --output text)
if [ -z "$INSTANCE_ID" ]; then echo '❌ No se encontró FidexAppsProd4' | tee -a $LOG_FILE; exit 1; fi
aws ec2 stop-instances --instance-ids $INSTANCE_ID | tee -a $LOG_FILE
aws ec2 wait instance-stopped --instance-ids $INSTANCE_ID
aws ec2 modify-instance-attribute --instance-id $INSTANCE_ID --instance-type '{"Value":"t3.micro"}' | tee -a $LOG_FILE
aws ec2 start-instances --instance-ids $INSTANCE_ID | tee -a $LOG_FILE
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
echo '✅ FidexAppsProd4 redimensionada a t3.micro' | tee -a $LOG_FILE
echo "FidexAppsProd4" >> $CHECKPOINT_FILE

# Revisar si ya se procesó FidexAppsProd5
if grep -q "^FidexAppsProd5$" $CHECKPOINT_FILE; then
    echo '⏩ FidexAppsProd5 ya fue procesada, omitiendo...' | tee -a $LOG_FILE
    continue
fi

echo '--- Procesando FidexAppsProd5 ---' | tee -a $LOG_FILE
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=FidexAppsProd5" --query "Reservations[].Instances[].InstanceId" --output text)
if [ -z "$INSTANCE_ID" ]; then echo '❌ No se encontró FidexAppsProd5' | tee -a $LOG_FILE; exit 1; fi
aws ec2 stop-instances --instance-ids $INSTANCE_ID | tee -a $LOG_FILE
aws ec2 wait instance-stopped --instance-ids $INSTANCE_ID
aws ec2 modify-instance-attribute --instance-id $INSTANCE_ID --instance-type '{"Value":"t3.medium"}' | tee -a $LOG_FILE
aws ec2 start-instances --instance-ids $INSTANCE_ID | tee -a $LOG_FILE
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
echo '✅ FidexAppsProd5 redimensionada a t3.medium' | tee -a $LOG_FILE
echo "FidexAppsProd5" >> $CHECKPOINT_FILE

# Revisar si ya se procesó FidexAppsProd7
if grep -q "^FidexAppsProd7$" $CHECKPOINT_FILE; then
    echo '⏩ FidexAppsProd7 ya fue procesada, omitiendo...' | tee -a $LOG_FILE
    continue
fi

echo '--- Procesando FidexAppsProd7 ---' | tee -a $LOG_FILE
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=FidexAppsProd7" --query "Reservations[].Instances[].InstanceId" --output text)
if [ -z "$INSTANCE_ID" ]; then echo '❌ No se encontró FidexAppsProd7' | tee -a $LOG_FILE; exit 1; fi
aws ec2 stop-instances --instance-ids $INSTANCE_ID | tee -a $LOG_FILE
aws ec2 wait instance-stopped --instance-ids $INSTANCE_ID
aws ec2 modify-instance-attribute --instance-id $INSTANCE_ID --instance-type '{"Value":"t3.nano"}' | tee -a $LOG_FILE
aws ec2 start-instances --instance-ids $INSTANCE_ID | tee -a $LOG_FILE
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
echo '✅ FidexAppsProd7 redimensionada a t3.nano' | tee -a $LOG_FILE
echo "FidexAppsProd7" >> $CHECKPOINT_FILE

# Revisar si ya se procesó FidexAppsProd9
if grep -q "^FidexAppsProd9$" $CHECKPOINT_FILE; then
    echo '⏩ FidexAppsProd9 ya fue procesada, omitiendo...' | tee -a $LOG_FILE
    continue
fi

echo '--- Procesando FidexAppsProd9 ---' | tee -a $LOG_FILE
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=FidexAppsProd9" --query "Reservations[].Instances[].InstanceId" --output text)
if [ -z "$INSTANCE_ID" ]; then echo '❌ No se encontró FidexAppsProd9' | tee -a $LOG_FILE; exit 1; fi
aws ec2 stop-instances --instance-ids $INSTANCE_ID | tee -a $LOG_FILE
aws ec2 wait instance-stopped --instance-ids $INSTANCE_ID
aws ec2 modify-instance-attribute --instance-id $INSTANCE_ID --instance-type '{"Value":"t3a.large"}' | tee -a $LOG_FILE
aws ec2 start-instances --instance-ids $INSTANCE_ID | tee -a $LOG_FILE
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
echo '✅ FidexAppsProd9 redimensionada a t3a.large' | tee -a $LOG_FILE
echo "FidexAppsProd9" >> $CHECKPOINT_FILE

# Revisar si ya se procesó FidexSopProd3
if grep -q "^FidexSopProd3$" $CHECKPOINT_FILE; then
    echo '⏩ FidexSopProd3 ya fue procesada, omitiendo...' | tee -a $LOG_FILE
    continue
fi

echo '--- Procesando FidexSopProd3 ---' | tee -a $LOG_FILE
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=FidexSopProd3" --query "Reservations[].Instances[].InstanceId" --output text)
if [ -z "$INSTANCE_ID" ]; then echo '❌ No se encontró FidexSopProd3' | tee -a $LOG_FILE; exit 1; fi
aws ec2 stop-instances --instance-ids $INSTANCE_ID | tee -a $LOG_FILE
aws ec2 wait instance-stopped --instance-ids $INSTANCE_ID
aws ec2 modify-instance-attribute --instance-id $INSTANCE_ID --instance-type '{"Value":"c5.large"}' | tee -a $LOG_FILE
aws ec2 start-instances --instance-ids $INSTANCE_ID | tee -a $LOG_FILE
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
echo '✅ FidexSopProd3 redimensionada a c5.large' | tee -a $LOG_FILE
echo "FidexSopProd3" >> $CHECKPOINT_FILE

# Revisar si ya se procesó FidexSopProd4
if grep -q "^FidexSopProd4$" $CHECKPOINT_FILE; then
    echo '⏩ FidexSopProd4 ya fue procesada, omitiendo...' | tee -a $LOG_FILE
    continue
fi

echo '--- Procesando FidexSopProd4 ---' | tee -a $LOG_FILE
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=FidexSopProd4" --query "Reservations[].Instances[].InstanceId" --output text)
if [ -z "$INSTANCE_ID" ]; then echo '❌ No se encontró FidexSopProd4' | tee -a $LOG_FILE; exit 1; fi
aws ec2 stop-instances --instance-ids $INSTANCE_ID | tee -a $LOG_FILE
aws ec2 wait instance-stopped --instance-ids $INSTANCE_ID
aws ec2 modify-instance-attribute --instance-id $INSTANCE_ID --instance-type '{"Value":"t3.micro"}' | tee -a $LOG_FILE
aws ec2 start-instances --instance-ids $INSTANCE_ID | tee -a $LOG_FILE
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
echo '✅ FidexSopProd4 redimensionada a t3.micro' | tee -a $LOG_FILE
echo "FidexSopProd4" >> $CHECKPOINT_FILE

# Revisar si ya se procesó FidexDBProd1
if grep -q "^FidexDBProd1$" $CHECKPOINT_FILE; then
    echo '⏩ FidexDBProd1 ya fue procesada, omitiendo...' | tee -a $LOG_FILE
    continue
fi

echo '--- Procesando FidexDBProd1 ---' | tee -a $LOG_FILE
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=FidexDBProd1" --query "Reservations[].Instances[].InstanceId" --output text)
if [ -z "$INSTANCE_ID" ]; then echo '❌ No se encontró FidexDBProd1' | tee -a $LOG_FILE; exit 1; fi
aws ec2 stop-instances --instance-ids $INSTANCE_ID | tee -a $LOG_FILE
aws ec2 wait instance-stopped --instance-ids $INSTANCE_ID
aws ec2 modify-instance-attribute --instance-id $INSTANCE_ID --instance-type '{"Value":"c5.large"}' | tee -a $LOG_FILE
aws ec2 start-instances --instance-ids $INSTANCE_ID | tee -a $LOG_FILE
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
echo '✅ FidexDBProd1 redimensionada a c5.large' | tee -a $LOG_FILE
echo "FidexDBProd1" >> $CHECKPOINT_FILE

echo '✅ Todas las instancias fueron procesadas correctamente.' | tee -a $LOG_FILE