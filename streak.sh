#!/bin/sh
database="mongo"
declare -a props
endofprops=false
read -p "Name your model example (Student): " name

until [ "$endofprops" = true ]
do
  read -p "Add property example(String id): " prop
  if [ "$prop" != "end" ]
  then
    props+="$prop,"
  else
    endofprops=true
  fi
done

for i in "${props[@]}"; do echo "$i"; done
cat > $name.java << ENDOFFILE
import org.springframework.stereotype.Component;

@Document
public class $name{
  $(
    SAVEIFS=$IFS  
    IFS=$',' 
    names=($props)
    IFS=$SAVEIFS

    for (( i=0; i<${#names[@]}; i++ ))
    do
        echo "private ${names[$i]};"
    done
  )

}
ENDOFFILE
