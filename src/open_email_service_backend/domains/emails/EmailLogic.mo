import Principal "mo:base/Principal";
import TrieMap "mo:base/TrieMap";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Result "mo:base/Result";

import Option "mo:base/Option";
import List "mo:base/List";
import Iter "mo:base/Iter";
import Bool "mo:base/Bool";
import Array "mo:base/Array";
import Order "mo:base/Order";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";

import Utils "../../utils/helper";

import T "EmailTypes";

module {

    public class EmailManager() {

        let utils = Utils.Utlis();

        private var emailStore : TrieMap.TrieMap<Text, T.Email> = TrieMap.TrieMap<Text, T.Email>(Text.equal, Text.hash);
        private var fileStore : TrieMap.TrieMap<Text, T.File> = TrieMap.TrieMap<Text, T.File>(Text.equal, Text.hash);
        private var registry : TrieMap.TrieMap<Principal, T.EmailRegistry> = TrieMap.TrieMap<Principal, T.EmailRegistry>(Principal.equal, Principal.hash);

        public func sendEmail(senderAddress : ?Text, senderPrincipalId : Principal, recipientPrinicpalIdOpt : ?Principal, mail : T.SendEmailDTO) : async Result.Result<T.Email, T.EmailErrors> {
            //generate new uuid key
            var uuidKey : Text = await utils.generateUUID();

            let recipientPrinicpalId : Principal = Option.get(recipientPrinicpalIdOpt, Principal.fromText("aaaaa-aa"));

            //determine if sender or reciver is valid
            if (senderAddress == null or recipientPrinicpalId == Principal.fromText("aaaaa-aa")) {
                return #err(#AnonymousCaller);
            };

            if (recipientPrinicpalIdOpt == null) {
                return #err(#InvalidRecipientAddress);
            };

            if (senderAddress == ?mail.to) {
                return #err(#ErrorSelfTransfer);
            };

            let emailRequest : T.Email = {
                from = Option.get(senderAddress, "");
                to = mail.to;
                subject = mail.subject;
                body = mail.body;
                attachmentIds = mail.attachmentIds;
                createdOn = Time.now();
            };

            //add email to the email store
            emailStore.put(uuidKey, emailRequest);

            //add it to senders outbox
            let senderRegistry : ?T.EmailRegistry = registry.get(senderPrincipalId);
            switch (senderRegistry) {
                // If registry exists, update the outbox
                case (?senderRegistry) {
                    let updatedOutbox = List.push(uuidKey, senderRegistry.outbox);
                    let updatedRegistry : T.EmailRegistry = {
                        inbox = senderRegistry.inbox;
                        outbox = updatedOutbox;
                        important = List.nil();
                        openedMails = List.nil();
                    };
                    registry.put(senderPrincipalId, updatedRegistry);

                };
                // If registry doesn't exist, create a new one
                case null {
                    let newOutbox = List.push(uuidKey, List.nil());
                    let newRegistry : T.EmailRegistry = {
                        inbox = List.nil();
                        outbox = newOutbox;
                        important = List.nil();
                        openedMails = List.nil();
                    };
                    registry.put(senderPrincipalId, newRegistry);
                };
            };

            //add it to recipeints inbox

            let reciverRegistry : ?T.EmailRegistry = registry.get(recipientPrinicpalId);

            switch (reciverRegistry) {
                // If registry exists, update the outbox
                case (?reciverRegistry) {
                    let updatedInbox = List.push(uuidKey, reciverRegistry.inbox);
                    let updatedRegistry : T.EmailRegistry = {
                        inbox = updatedInbox;
                        outbox = reciverRegistry.outbox;
                        important = List.nil();
                        openedMails = List.nil();
                    };
                    registry.put(recipientPrinicpalId, updatedRegistry);

                };
                // If registry doesn't exist, create a new one
                case null {
                    let newInbox = List.push(uuidKey, List.nil());
                    let newRegistry : T.EmailRegistry = {
                        inbox = newInbox;
                        outbox = List.nil();
                        important = List.nil();
                        openedMails = List.nil();
                    };
                    registry.put(recipientPrinicpalId, newRegistry);
                };
            };

            return #ok(emailRequest);
        };

        //get list of recevied mails
        public func fetchInboxMails(caller : Principal, pageNumber : Nat, pageSize : Nat) : async [T.EmailResponseDTO] {
            //authenticate user when fetching the emails.
            let receviedEmailIds : List.List<Text> = switch (registry.get(caller)) {
                case (?emailRegistry) emailRegistry.inbox;
                case null List.nil();
            };

            let emails = List.mapFilter<Text, T.EmailResponseDTO>(
                receviedEmailIds,
                func(id) {
                    switch (emailStore.get(id)) {
                        case (?email) {

                            let responseEmail : T.EmailResponseDTO = {
                                id = id;
                                from = email.from;
                                to = email.to;
                                subject = email.subject;
                                createdOn = email.createdOn;
                                starred = false;
                                readFlag = false;
                            };

                            return ?responseEmail;

                        }; // Extract the email if it exists
                        case null null; // Skip if the email is null
                    };
                },
            );

            return getPaginatedEmails(caller, pageNumber, pageSize, emails, false);

        };

        //get list of sent mails
        public func fetchOutboxMails(caller : Principal, pageNumber : Nat, pageSize : Nat) : async [T.EmailResponseDTO] {
            //authenticate user when fetching the emails.
            let sentEmailIds : List.List<Text> = switch (registry.get(caller)) {
                case (?emailRegistry) emailRegistry.outbox;
                case null List.nil();
            };

            let emails = List.mapFilter<Text, T.EmailResponseDTO>(
                sentEmailIds,
                func(id) {
                    switch (emailStore.get(id)) {
                        case (?email) {

                            let responseEmail : T.EmailResponseDTO = {
                                id = id;
                                from = email.from;
                                to = email.to;
                                subject = email.subject;
                                createdOn = email.createdOn;
                                starred = false;
                                readFlag = false;
                            };

                            return ?responseEmail;

                        }; // Extract the email if it exists
                        case null null; // Skip if the email is null
                    };
                },
            );

            return getPaginatedEmails(caller, pageNumber, pageSize, emails, true);

        };

        private func getPaginatedEmails(caller : Principal, pageNumber : Nat, pageSize : Nat, emails : List.List<T.EmailResponseDTO>, isOutboxRequest : Bool) : [T.EmailResponseDTO] {

            let allEmails = List.toArray(emails);

            // Sort by createdAt (newest first)
            let sortedEmails = Array.sort(
                allEmails,
                func(a : T.EmailResponseDTO, b : T.EmailResponseDTO) : Order.Order {
                    Int.compare(b.createdOn, a.createdOn); // Descending order
                },
            );

            // Calculate pagination bounds
            let startIdx = pageNumber * pageSize;

            // Handle case where start index is beyond array bounds
            if (startIdx >= sortedEmails.size()) {
                return [];
            };

            // Calculate safe end index (don't go beyond array bounds)
            let safeEndIdx = Nat.min(startIdx + pageSize, sortedEmails.size());

            // Properly convert slice to array
            let paginateEmails = Iter.toArray(Array.slice(sortedEmails, startIdx, safeEndIdx));

            // get read recipt
            let openedMails : List.List<Text> = getOpenedMailList(caller);

            //get starred email
            let importantMailsList : List.List<Text> = getImportantMailList(caller);

            //perform operations for processing flags.
            Array.map<T.EmailResponseDTO, T.EmailResponseDTO>(
                paginateEmails,
                func(email) {

                    //for outbox
                    let readFlag : Bool = if (isOutboxRequest) {
                        true;
                    } else {
                        switch (List.find<Text>(openedMails, func(listId) { listId == email.id })) {
                            case (?_) true;
                            case null false;
                        };
                    };

                    // Check if the current email ID exists in the importantMailsList
                    let isStarred = switch (List.find<Text>(importantMailsList, func(listId) { listId == email.id })) {
                        case (?_) true;
                        case null false;
                    };

                    // Return updated email with processed flags
                    {
                        email with
                        readFlag = readFlag;
                        starred = isStarred;
                    }

                },
            );
        };

        // mark it as important
        public func markItAsImportant(caller : Principal, emailId : Text) : () {

            let savedRecord : ?T.EmailRegistry = registry.get(caller);

            let importantMails : List.List<Text> = switch (savedRecord) {
                case (?emailRegistry) emailRegistry.important;
                case null List.nil();
            };

            let updatedImportantMailsList : List.List<Text> = List.push(emailId, importantMails);

            switch (savedRecord) {
                case (?savedRecord) {
                    let updatedRegistry : T.EmailRegistry = {
                        inbox = savedRecord.inbox;
                        outbox = savedRecord.outbox;
                        important = updatedImportantMailsList;
                        openedMails = List.nil();
                    };

                    //add updated records.
                    registry.put(caller, updatedRegistry);
                };
                case null {};
            };

        };

        public func getMailById(caller : Principal, emailId : Text) : Result.Result<T.EmailBodyResponseDTO, T.EmailErrors> {

            let savedEmail : ?T.Email = emailStore.get(emailId);
            switch (savedEmail) {
                case (?email) {
                    let attachmentsBuffer = Buffer.Buffer<T.FileResponseDTO>(email.attachmentIds.size());

                    for (fileId in email.attachmentIds.vals()) {
                        switch (fileStore.get(fileId)) {
                            case (?file) {
                                attachmentsBuffer.add({
                                    fileId = fileId;
                                    fileName = file.fileName;
                                    size = file.size;
                                });
                            };
                            case null {}; // do nothing, skip missing files
                        };
                    };
                    
                    //convert buffer to array list.
                    let attachments : [T.FileResponseDTO] = Buffer.toArray(attachmentsBuffer);

                    let emailRespose : T.EmailBodyResponseDTO = {
                        id = emailId;
                        from = email.from;
                        to = email.to;
                        subject = email.subject;
                        body = email.body;
                        attachments = ?attachments;
                        createdOn = email.createdOn;
                        starred = false; //todo:add logic later to make it highlighted if needed from FE.
                        readFlag = true;
                    };

                    //mark it as read
                    markAsRead(caller, emailId);
                    return #ok(emailRespose);
                };

                case null #err(#NotFound);
            }

        };

        //mark email as read
        private func markAsRead(caller : Principal, emailId : Text) : () {

            let savedRecord : ?T.EmailRegistry = registry.get(caller);

            let openedMailsList : List.List<Text> = switch (savedRecord) {
                case (?emailRegistry) emailRegistry.openedMails;
                case null List.nil();
            };

            let updateOpenedMailList : List.List<Text> = List.push(emailId, openedMailsList);

            switch (savedRecord) {
                case (?savedRecord) {
                    let updatedRegistry : T.EmailRegistry = {
                        inbox = savedRecord.inbox;
                        outbox = savedRecord.outbox;
                        important = savedRecord.important;
                        openedMails = updateOpenedMailList;
                    };

                    //add updated records.
                    registry.put(caller, updatedRegistry);
                };
                case null {};
            };

        };

        //delete all mails for the caller while deleting the profile.
        public func deleteMails(caller : Principal) : () {
            switch (registry.get(caller)) {
                case (?_) registry.delete(caller);
                case null {};
            };
        };

        //reused functions
        private func getImportantMailList(caller : Principal) : List.List<Text> {
            let savedRecord : ?T.EmailRegistry = registry.get(caller);

            let importantMails : List.List<Text> = switch (savedRecord) {
                case (?emailRegistry) emailRegistry.important;
                case null List.nil();
            };
            return importantMails;

        };

        private func getOpenedMailList(caller : Principal) : List.List<Text> {
            let savedRecord : ?T.EmailRegistry = registry.get(caller);

            let openedMails : List.List<Text> = switch (savedRecord) {
                case (?emailRegistry) emailRegistry.openedMails;
                case null List.nil();
            };
            return openedMails;
        };

        //Multimedia file handling methods.

        public func uploadFile(uploadedFile:T.FileRequestDTO) : async Result.Result<T.FileResponseDTO, T.FileErrors> {

            //generate new uuid key
            var uuidKey : Text = await utils.generateUUID();
            let file:T.File={
                fileId=uuidKey;
                fileName=uploadedFile.fileName;
                contentType=uploadedFile.contentType;
                size=uploadedFile.filedata.size();
                filedata=uploadedFile.filedata;

            };
            fileStore.put(uuidKey, file);

            //validate if operation is successfull or not
            switch (fileStore.get(uuidKey)) {
                case (?savedResponse) #ok({
                    fileId = uuidKey;
                    fileName = savedResponse.fileName;
                    size = savedResponse.size;
                });
                case null #err(#UnexpectedErrorOccured);
            };
        };

        public func getFile(fileId : Text) : Result.Result<T.File, T.FileErrors> {
            switch (fileStore.get(fileId)) {
                case (?savedFile) #ok(savedFile);
                case null #err(#NotFound);
            };
        };

        //data persistance
        public func getStableEmailStore() : [(Text, T.Email)] {
            return Iter.toArray(emailStore.entries());
        };

        public func setStableEmailStore(emails : [(Text, T.Email)]) : () {
            for (email : (Text, T.Email) in Iter.fromArray(emails)) {
                emailStore.put(email.0, email.1);
            };
        };

        public func getStableRegistries() : [(Principal, T.EmailRegistry)] {
            return Iter.toArray(registry.entries());
        };

        public func setStableRegistries(registries : [(Principal, T.EmailRegistry)]) : () {
            for (entry in Iter.fromArray(registries)) {
                registry.put(entry.0, entry.1);
            };
        };

        public func getStableFileStore() : [(Text, T.File)] {
            return Iter.toArray(fileStore.entries());
        };

        public func setStableFileStore(files : [(Text, T.File)]) : () {
            for (entry in Iter.fromArray(files)) {
                fileStore.put(entry.0, entry.1);
            };
        };

    };
};
