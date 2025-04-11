import Blob "mo:base/Blob";
import Time "mo:base/Time";
import Text "mo:base/Text";

module{

    public type Timestamp = Int;

    // Main Profile type
    public type Profile={
        id:Text;
        name:Text;
        surname:Text;
        userAddress:Text;
        status:?Text;
        description:?Text;
        profileImage:?Blob;
        createdOn: Timestamp;
    };

    public type CreateProfileDTO={
        name:Text;
        surname:Text;
        userAddress:Text;
        status:?Text;
        description:?Text;
        profileImage:?Blob;
    };

    // Main error type variant
    public type ProfileError={
        #NotFound;
        #AlreadyExists:Text;
        #InvalidData : Text ;
        #AnonymousCaller;
    };
    
    // Success/Error result type
    public type ProfileResult = {
        #ok ;
        #err : ProfileError;
    };

}