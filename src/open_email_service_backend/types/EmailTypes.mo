import List "mo:base/List";
import Text "mo:base/Text";
import Bool "mo:base/Bool";
import Blob "mo:base/Blob";

module {

    public type Timestamp = Int;

    public type Email = {
        from : Text;
        to : Text;
        subject : ?Text;
        body : Text;
        attachmentIds : [Text];
        createdOn : Timestamp;
        isReply : Bool;
        parentMailId : ?Text;
    };

    public type Thread = {
        headMailId : Text; // Points to the first message in thread
        replyMailIds : [Text]; // All replies in this thread
        isNewMailAdded : Bool;
    };

    public type TrashMetaData = {
        deleteAfter : Timestamp; // Unix timestamp or duration in seconds
        source : Text;
        threads:[Text]; // list of ids to be deleted in case of threads.
    };

    public type EmailRegistry = {
        inbox : List.List<Text>;
        outbox : List.List<Text>;
        important : List.List<Text>;
        openedMails : List.List<Text>;
        trash: List.List<(Text, TrashMetaData)>;
    };

    public type EmailErrors = {
        #NotFound;
        #AnonymousCaller;
        #InvalidRecipientAddress;
        #ErrorSelfTransfer;
        #MissingParentId;
        #UnknownSource;
    };

    public type File = {
        fileId : Text;
        fileName : Text;
        contentType : Text;
        size : Nat;
        filedata : Blob;
    };

    public type FileErrors = {
        #NotFound;
        #UnexpectedErrorOccured;
    };

};
