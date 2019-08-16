#!/bin/bash
database="mongo"
declare -a props
endofprops=false
read -p "Name your model example (Student): " name

until [ "$endofprops" = true ]
do
  read -p "Add property example(String id): " prop
  if [ "$prop" != "end" ]
  then
    props+=$prop
  else
    endofprops=true
  fi
done


cat > $name.java << ENDOFFILE
import org.springframework.stereotype.Component;

@Document
public class $name{
  $(for i in "${props[@]}"; do "private $i;\n"; done)
}
ENDOFFILE


