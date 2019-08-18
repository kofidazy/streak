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

mkdir $name

echo "********** Starting JOB **********"

SAVEIFS=$IFS  
IFS=$',' 
names=($props)
IFS=$SAVEIFS

createRepository(){
cat > $name/${name}Repository.java << ENDOFFILE
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.io.Serializable;
import java.util.List;

@Repository
public interface ${name}Repository extends MongoRepository<$name, Serializable> {
$(for (( i=0; i<${#names[@]}; i++ ))
do
  type=$(echo ${names[$i]} | cut -d' ' -f 1)
  variable=$(echo ${names[$i]} | cut -d' ' -f 2)
  echo "$name findBy${variable^}(${names[$i]});"
done
)
}

ENDOFFILE
}

createModel(){
cat > $name/$name.java << ENDOFFILE
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
      
 
      echo "private $type get${variable^}() { return $variable; }"
      echo "private void set${variable^}(${names[$i]}) { this.$variable = $variable; }"

  done

)

}
ENDOFFILE

}

createJsonResponse(){
cat > $name/JsonResponse.java << ENDOFFILE
import org.springframework.stereotype.Component;

@Component
public class JsonResponse {

    private boolean status;
    private Object result;
    private String message;
    private long count;

    public JsonResponse(boolean status, Object result, String message, long count) {
        this.status = status;
        this.result = result;
        this.message = message;
        this.count = count;
    }

    public JsonResponse() {
    }
    public boolean getStatus() {
        return status;
    }
    public void setStatus(boolean status) {
        this.status = status;
    }
    public Object getResult() {
        return result;
    }
    public void setResult(Object result) {
        this.result = result;
    }
    public long getCount() {
        return count;
    }
    public void setCount(long count) {
        this.count = count;
    }
    public String getMessage() {
        return message;
    }
    public void setMessage(String message) {
        this.message = message;
    }
}
ENDOFFILE
}

createJsonBuilder(){
cat > $name/JsonResponseBuilder.java << ENDOFFILE
public class JsonResponseBuilder {
    private boolean status;
    private Object result;
    private String message;
    private long count;

    public JsonResponseBuilder setStatus(boolean status) {
        this.status = status;
        return this;
    }

    public JsonResponseBuilder setResult(Object result) {
        this.result = result;
        return this;
    }

    public JsonResponseBuilder setMessage(String message) {
        this.message = message;
        return this;
    }

    public JsonResponseBuilder setCount(long count) {
        this.count = count;
        return this;
    }

    public JsonResponse createJsonResponse() {
        return new JsonResponse(status, result, message, count);
    }
}
ENDOFFILE
}

createService(){
cat > $name/${name}Service.java << ENDOFFILE
import org.springframework.data.domain.Pageable;

public interface Service$name {
$(
for (( i=0; i<${#names[@]}; i++ ))
do
  type=$(echo ${names[$i]} | cut -d' ' -f 1)
  variable=$(echo ${names[$i]} | cut -d' ' -f 2)
  if [ "$variable" = "id" ]
  then 
    echo "JsonResponse findById(String id);"        
  fi
done
echo "JsonResponse create$name($name ${name,});"
echo "JsonResponse search$name(String searchParam, Pageable pageable);"
echo "JsonResponse list$name(Pageable pageable);"
echo "$name update$name($name ${name,});"
)
}
ENDOFFILE
}

createEnum(){
cat > $name/Messages.java << ENDOFFILE
public enum Messages{
  Failed,
  Success
}
ENDOFFILE
}

createValidation(){
cat > $name/Validation.java << ENDOFFILE
import java.util.Optional;

public class Validation {

    public static JsonResponse check(Optional optional, Enum goodMessage, Enum badMessage){
        if (optional.isPresent()){
            return Json.good(goodMessage,optional.get());
        }else{
            return Json.bad(badMessage);
        }
    }
}
ENDOFFILE
}

createJson(){
cat > $name/Json.java << ENDOFFILE

import com.vis.models.JsonResponse;
import com.vis.models.JsonResponseBuilder;
public class Json {
    public static JsonResponse bad(Enum m){
        return new JsonResponseBuilder()
                .setMessage(removeUnderscores(m.toString()))
                .setStatus(false)
                .createJsonResponse();
    }

    public static JsonResponse good(Enum m){
        return new JsonResponseBuilder()
                .setMessage(removeUnderscores(m.toString()))
                .setStatus(true)
                .createJsonResponse();
    }

    public static JsonResponse good(Enum m, Object o){
        return new JsonResponseBuilder()
                .setMessage(removeUnderscores(m.toString()))
                .setStatus(true)
                .setResult(o)
                .createJsonResponse();
    }

    public static JsonResponse good(Enum m, Object o, int count){
        return new JsonResponseBuilder()
                .setMessage(removeUnderscores(m.toString()))
                .setStatus(true)
                .setResult(o)
                .setCount(count)
                .createJsonResponse();
    }
    public static String removeUnderscores(String result) {
        return result.replaceAll("[_]"," ");
    }
    public static boolean isNullOrEmpty(String str) {
        if(str != null && !str.trim().isEmpty())
            return false;
        return true;
    }
}
ENDOFFILE
}

createServiceImpl(){
cat > $name/${name}ServiceImpl.java << ENDOFFILE
import org.springframework.data.domain.Pageable;

@Component
public class ${name}ServiceImpl implements ${name}Service{

@Autowired
private ${name}Repository ${name,}Repository;

$(
for (( i=0; i<${#names[@]}; i++ ))
do
  type=$(echo ${names[$i]} | cut -d' ' -f 1)
  variable=$(echo ${names[$i]} | cut -d' ' -f 2)
  if [ "$variable" = "id" ]
  then 
    echo "  
    private JsonResponse findById(String id){  
      Optional<$name> res = Optional.ofNullable(${name,}Repository.findById(id));
      return Validation.check(res, Messages.Success, Messages.Failed);
    } "       
  fi
done
    echo "JsonResponse create$name($name ${name,});"
    echo "JsonResponse search$name(String searchParam, Pageable pageable);"
    echo "JsonResponse list$name(Pageable pageable);"
    echo "$name update$name($name ${name,});"
)


}
ENDOFFILE
}

echo "Creating Model..."
createModel
echo "Creating Repository..."
createRepository
echo "Creating JSON Model..."
createJsonResponse
createJson
echo "Creating JSON Builder"
createJsonBuilder
echo "Creating Enums"
createEnum
echo "Creating ServiceInterface..."
createService
echo "Creating Service"
createServiceImpl
echo "********** JOB COMPLETE!! **********"
