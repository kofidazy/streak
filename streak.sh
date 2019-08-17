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

SAVEIFS=$IFS  
IFS=$',' 
names=($props)
IFS=$SAVEIFS

createRepository(){
cat > Repository$name.java << ENDOFFILE
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.io.Serializable;
import java.util.List;

@Repository
public interface Repository$name extends MongoRepository<$name, Serializable> {
    $(for (( i=0; i<${#names[@]}; i++ ))
  do
      type=$(echo ${names[$i]} | cut -d' ' -f 1)
      variable=$(echo ${names[$i]} | cut -d' ' -f 2)
      echo "$name findBy$variable(${names[$i]});"
  done
  )
}

ENDOFFILE
}

createModel(){
cat > $name.java << ENDOFFILE
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

@Document
public class $name{

$(
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

}


createModel
createRepository
