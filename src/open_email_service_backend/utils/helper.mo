import Text "mo:base/Text";
import Random "mo:base/Random";
import UUID "mo:idempotency-keys/idempotency-keys";


module{

    public class Utlis(){
        
        public func generateUUID() : async Text{
            let entropy = await Random.blob();
            let idempotentKey:Text=UUID.generateV4(entropy);
            return idempotentKey;   
        };
    }


};