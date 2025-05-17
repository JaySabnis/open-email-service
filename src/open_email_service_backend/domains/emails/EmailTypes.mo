import List "mo:base/List";
import Text "mo:base/Text";
import Bool "mo:base/Bool";
import Blob "mo:base/Blob";

module{
    
    public type Timestamp = Int;
    
    public type Email={
        from:Text;
        to:Text;
        subject:Text;
        body:Text;
        attachmentIds:[Text];
        createdOn:Timestamp;
        //add parent mail id for threading
    };

    public type SendEmailDTO={
        to:Text;
        subject:Text;
        body:Text;
        attachmentIds:[Text];
    };

    public type EmailResponseDTO={
        id:Text;
        from:Text;
        to:Text;
        subject:Text;
        createdOn:Timestamp;
        starred:Bool;
        readFlag:Bool;
        //add parent mail id for threading
    };

    public type EmailBodyResponseDTO={
        id:Text;
        from:Text;
        to:Text;
        subject:Text;
        body:Text;
        attachments:[FileResponseDTO];
        createdOn:Timestamp;
        starred:Bool;
        readFlag:Bool;
        //add parent mail id for threading
    };


    public type EmailRegistry={
        inbox:List.List<Text>;
        outbox:List.List<Text>; 
        important:List.List<Text>;
        openedMails:List.List<Text>;
    };

    public type EmailErrors={
        #NotFound;
        #AnonymousCaller;
        #InvalidRecipientAddress;
        #ErrorSelfTransfer;
    };

    public type File = {
        fileId: Text;
        fileName: Text;
        contentType: Text;
        size: Nat;         
        filedata: Blob;
    };

    public type FileRequestDTO = {
        fileName: Text;
        contentType: Text;        
        filedata: Blob;
    };

    public type FileResponseDTO={
        fileId: Text;
        fileName: Text;  
        size:Nat;
    };

    public type FileErrors={
        #NotFound;
        #UnexpectedErrorOccured;
    };

};