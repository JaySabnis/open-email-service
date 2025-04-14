import Principal "mo:base/Principal";
import List "mo:base/List";
import Text "mo:base/Text";

module{
    
    public type Timestamp = Int;
    
    public type Email={
        from:Text;
        to:Text;
        subject:Text;
        body:Text;
        createdOn:Timestamp;
        //add parent mail id for threading
    };

    public type SendEmailDTO={
        to:Text;
        subject:Text;
        body:Text;
    };

     public type EmailResponseDTO={
        id:Text;
        from:Text;
        to:Text;
        subject:Text;
        body:Text;
        createdOn:Timestamp;
        //add parent mail id for threading
    };


    public type EmailRegistry={
        inbox:List.List<Text>;
        outbox:List.List<Text>; 
    };

    public type EmailErrors={
        #NotFound;
        #AnonymousCaller;
        #InvalidRecipientAddress;
        #ErrorSelfTransfer;
    };

    

};