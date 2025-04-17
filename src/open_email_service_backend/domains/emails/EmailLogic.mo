import Principal "mo:base/Principal";
import TrieMap "mo:base/TrieMap";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Result "mo:base/Result";

import Option "mo:base/Option";
import List "mo:base/List";
import Iter "mo:base/Iter";
import Bool "mo:base/Bool";


import Utils "../../utils/helper";

import T "EmailTypes";
import EmailTypes "EmailTypes";



module{

    public class EmailManager(){

        let utils=Utils.Utlis();
        let now:T.Timestamp = Time.now();

        private var emailStore:TrieMap.TrieMap<Text,T.Email> = TrieMap.TrieMap<Text,T.Email>(Text.equal,Text.hash);
        private var registry:TrieMap.TrieMap<Principal,T.EmailRegistry> = TrieMap.TrieMap<Principal,T.EmailRegistry>(Principal.equal,Principal.hash);

        
        public func sendEmail(senderAddress:?Text,senderPrincipalId:Principal,recipientPrinicpalIdOpt:?Principal,mail:T.SendEmailDTO) : async Result.Result<T.Email,T.EmailErrors>{
            //generate new uuid key
            var uuidKey:Text = await utils.generateUUID();

            let recipientPrinicpalId:Principal=Option.get(recipientPrinicpalIdOpt,Principal.fromText("aaaaa-aa"));
   
            //determine if sender or reciver is valid
            if(senderAddress==null or recipientPrinicpalId==Principal.fromText("aaaaa-aa")){
                return #err(#AnonymousCaller); 
            };

            if(recipientPrinicpalIdOpt==null){
                return #err(#InvalidRecipientAddress);
            };
            
            if(senderAddress==?mail.to){
                return #err(#ErrorSelfTransfer);
            };

            let emailRequest:T.Email={
                from=Option.get(senderAddress,"");
                to=mail.to;
                subject=mail.subject;
                body=mail.body;
                createdOn=now;
                starred=false; //by deafult it wont be starred.
            };

            //add email to the email store
            emailStore.put(uuidKey,emailRequest);

            //add it to senders outbox
            let senderRegistry:?T.EmailRegistry=registry.get(senderPrincipalId);
            switch(senderRegistry){
                // If registry exists, update the outbox
                case(?senderRegistry){
                    let updatedOutbox = List.push(uuidKey, senderRegistry.outbox);
                    let updatedRegistry:T.EmailRegistry={
                        inbox=senderRegistry.inbox;
                        outbox=updatedOutbox;
                        important=List.nil();
                    };
                    registry.put(senderPrincipalId,updatedRegistry);
                    
                };
                // If registry doesn't exist, create a new one
                case null{
                    let newOutbox=List.push(uuidKey,List.nil());
                    let newRegistry:T.EmailRegistry={
                        inbox=List.nil();
                        outbox=newOutbox;
                        important=List.nil();
                    };
                    registry.put(senderPrincipalId,newRegistry);
                };
            };

            //add it to recipeints inbox

           
            let reciverRegistry:?T.EmailRegistry=registry.get(recipientPrinicpalId);
        
            switch(reciverRegistry){
                // If registry exists, update the outbox
                case(?reciverRegistry){
                    let updatedInbox = List.push(uuidKey, reciverRegistry.inbox);
                    let updatedRegistry:T.EmailRegistry={
                        inbox=updatedInbox;
                        outbox=reciverRegistry.outbox;
                        important=List.nil();
                    };
                    registry.put(recipientPrinicpalId,updatedRegistry);
                    
                };
                // If registry doesn't exist, create a new one
                case null{
                    let newInbox=List.push(uuidKey,List.nil());
                    let newRegistry:T.EmailRegistry={
                        inbox=newInbox;
                        outbox=List.nil();
                        important=List.nil();
                    };
                    registry.put(recipientPrinicpalId,newRegistry);
                };
            };

            return #ok(emailRequest);
        };


        //get list of recevied mails
        public func fetchInboxMails(caller:Principal): async List.List<T.EmailResponseDTO>{
            //authenticate user when fetching the emails.
            let receviedEmailIds:List.List<Text> = switch(registry.get(caller)){
                case(?emailRegistry) emailRegistry.inbox;
                case null List.nil();
            };
            
            let importantMailsList:List.List<Text> = getImportantMailList(caller);

            let emails = List.mapFilter<Text, T.EmailResponseDTO>(receviedEmailIds, func(id) {

            // Check if the current email ID exists in the importantMailsList
            let isStarred=switch(List.find<Text>(importantMailsList, func(listId){listId==id})){
                case(?_) true;
                case null false;
            };

            switch (emailStore.get(id)) {
                    case (?email) {

                            let responseEmail:T.EmailResponseDTO={
                                id=id;
                                from=email.from;
                                to=email.to;
                                subject=email.subject;
                                body=email.body;
                                createdOn=email.createdOn;   
                                starred=isStarred;
                            };

                            return ?responseEmail;

                    }; // Extract the email if it exists
                    case null null;       // Skip if the email is null
                }
            });

            return emails;

        };


        //get list of sent mails
        public func fetchOutboxMails(caller:Principal): async List.List<T.EmailResponseDTO>{
            //authenticate user when fetching the emails.
            let sentEmailIds:List.List<Text> = switch(registry.get(caller)){
                case(?emailRegistry) emailRegistry.outbox;
                case null List.nil();
            };

            let importantMailsList:List.List<Text> = getImportantMailList(caller);
            let emails = List.mapFilter<Text, T.EmailResponseDTO>(sentEmailIds, func(id) {
            
            // Check if the current email ID exists in the importantMailsList
            let isStarred=switch(List.find<Text>(importantMailsList, func(listId){listId==id})){
                case(?_) true;
                case null false;
            };

            switch (emailStore.get(id)) {
                    case (?email) {

                            let responseEmail:T.EmailResponseDTO={
                                id=id;
                                from=email.from;
                                to=email.to;
                                subject=email.subject;
                                body=email.body;
                                createdOn=email.createdOn; 
                                starred=isStarred;   
                            };

                            return ?responseEmail;

                    }; // Extract the email if it exists
                    case null null;       // Skip if the email is null
                }
            });

            return emails;

        };
         

        // mark it as important
        public func markItAsImportant(caller:Principal,emailId:Text):(){

            let savedRecord:?EmailTypes.EmailRegistry=registry.get(caller);

            let importantMails:List.List<Text> = switch(savedRecord){
                case(?emailRegistry) emailRegistry.important;
                case null List.nil();
            };

            let updatedImportantMailsList:List.List<Text> = List.push(emailId,importantMails);

            switch(savedRecord) {
                case(?savedRecord) { 
                    let updatedRegistry:EmailTypes.EmailRegistry={
                        inbox=savedRecord.inbox;
                        outbox=savedRecord.outbox;
                        important=updatedImportantMailsList;
                    };

                    //add updated records.
                    registry.put(caller,updatedRegistry);
                 };
                case null {};
            };   

        };
        

        private func getImportantMailList(caller:Principal):List.List<Text>{
            let savedRecord:?EmailTypes.EmailRegistry=registry.get(caller);

            let importantMails:List.List<Text> = switch(savedRecord){
                case(?emailRegistry) emailRegistry.important;
                case null List.nil();
            };
            return importantMails;

        };

        public func getMailById(emailId:Text):Result.Result<EmailTypes.EmailResponseDTO,EmailTypes.EmailErrors>{

            //todo authentication of user;

            let savedEmail:?EmailTypes.Email=emailStore.get(emailId);
            switch(savedEmail){
                case(?email){
                    let emailRespose:EmailTypes.EmailResponseDTO={
                                id=emailId;
                                from=email.from;
                                to=email.to;
                                subject=email.subject;
                                body=email.body;
                                createdOn=email.createdOn; 
                                starred=false;   //todo:add logic later to make it highlighted if needed from FE.

                    };
                //add logic to mark it as read
                return #ok(emailRespose);
                };
                case null #err(#NotFound);
            }

        };

        //data persistance
        public func getStableEmailStore():[(Text,T.Email)]{
            return Iter.toArray(emailStore.entries());
        };

        public func setStableEmailStore(emails:[(Text,T.Email)]):(){
            for(email:(Text,T.Email) in Iter.fromArray(emails)){
                emailStore.put(email.0,email.1);
            }
        };

        public func getStableRegistries():[(Principal,T.EmailRegistry)]{
            return Iter.toArray(registry.entries());
        };

        public func setStableRegistries(registries:[(Principal,T.EmailRegistry)]):(){
            for(entry in Iter.fromArray(registries)){
                registry.put(entry.0,entry.1);
            }
        }
       
    };
};