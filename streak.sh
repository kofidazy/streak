#!/bin/sh
database="mongo"
declare -a props
endofprops=false
property_regex='^/s.+;$'

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

echo "Job complete!!!!"
cat > $name.java << ENDOFFILE
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Document
public class $name{

$(
  SAVEIFS=$IFS  
  IFS=$',' 
  names=($props)
  IFS=$SAVEIFS

  for (( i=0; i<${#names[@]}; i++ ))
  do
      type=$(echo ${names[$i]} | cut -d' ' -f 1)
      variable=$(echo ${names[$i]} | cut -d' ' -f 2)

      if [ "$variable" = "id" ]
      then 
        echo "@Id private ${names[$i]};"
      else
        echo "private ${names[$i]};"
      fi
  done
  
  for (( i=0; i<${#names[@]}; i++ ))
  do
      type=$(echo ${names[$i]} | cut -d' ' -f 1)
      variable=$(echo ${names[$i]} | cut -d' ' -f 2)
      

      echo "private $type get$variable() { return $variable; }"
      echo "private void set$variable(${names[$i]}) { this.$variable = $variable; }"

  done

)

}
ENDOFFILE
