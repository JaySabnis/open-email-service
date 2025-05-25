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

import Utils "../utils/helper";

import T "../types/EmailTypes";
import EmailCommands "../commands/EmailCommands";
import EmailQueries "../queries/EmailQueries";

module {

    public class EmailManager() {

        let utils = Utils.Utlis();

        private var emailStore : TrieMap.TrieMap<Text, T.Email> = TrieMap.TrieMap<Text, T.Email>(Text.equal, Text.hash);
        private var fileStore : TrieMap.TrieMap<Text, T.File> = TrieMap.TrieMap<Text, T.File>(Text.equal, Text.hash);
        private var threads : TrieMap.TrieMap<Text, T.Thread> = TrieMap.TrieMap<Text, T.Thread>(Text.equal, Text.hash);
        private var registry : TrieMap.TrieMap<Principal, T.EmailRegistry> = TrieMap.TrieMap<Principal, T.EmailRegistry>(Principal.equal, Principal.hash);

        public func sendEmail(senderAddress : Text, senderPrincipalId : Principal, recipientPrinicpalId : Principal, mail : EmailCommands.SendEmailDTO) : async Result.Result<T.Email, T.EmailErrors> {
            //generate new uuid key
            var uuidKey : Text = await utils.generateUUID();


            //determine if sender or reciver is valid
            if (senderAddress == mail.to) {
                return #err(#ErrorSelfTransfer);
            };

            let parentMailId : ?Text = if (mail.isReply) {
                mail.parentMailId;
            } else {
                null; // todo throw error saying parent id doesnt exit for reply.
            };

            let emailRequest : T.Email = {
                from = senderAddress;
                to = mail.to;
                subject = mail.subject;
                body = mail.body;
                attachmentIds = mail.attachmentIds;
                createdOn = Time.now();
                isReply = mail.isReply;
                parentMailId = parentMailId; // add only if thread exist.
            };

            //add email to the email store
            emailStore.put(uuidKey, emailRequest);

            //create thread.// need to optimise the function.
            switch (parentMailId) {
                case (?pid) {
                    createThread(uuidKey, pid); // only called if parentMailId exists
                };
                case null {
                    // do nothing or fallback logic
                };
            };

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

        // Create a thread of mails
        public func createThread(mailId : Text, parentMailId : Text) : () {

            let emailThread : ?T.Thread = threads.get(parentMailId);
            switch (emailThread) {
                case (?existingThread) {
                    let updatedReplyMailIdList : [Text] = Array.append(existingThread.replyMailIds, [mailId]); //todo:in case of duplicate reply ids , need to add condition to check if that paricular id exist or not.
                    let updatedThread : T.Thread = {
                        headMailId = existingThread.headMailId;
                        replyMailIds = updatedReplyMailIdList;
                        isNewMailAdded = true;
                    };
                    threads.put(parentMailId, updatedThread);
                };

                //create new thread in case it doesnt exist
                case null {
                    let newReplyMailIdList : [Text] = [mailId];
                    let newThread : T.Thread = {
                        headMailId = parentMailId;
                        replyMailIds = newReplyMailIdList;
                        isNewMailAdded = true;
                    };
                    threads.put(parentMailId, newThread);
                };
            };
        };

        //get list of recevied mails
        public func fetchInboxMails(caller : Principal, pageNumber : ?Nat, pageSize : ?Nat) : async [T.EmailResponseDTO] {
            //authenticate user when fetching the emails.
            let receviedEmailIds : List.List<Text> = switch (registry.get(caller)) {
                case (?emailRegistry) emailRegistry.inbox;
                case null List.nil();
            };

            // todo:instead of fetching all mails just fetch latest mails
            let emails = List.mapFilter<Text, T.EmailResponseDTO>(
                receviedEmailIds,
                func(id) {
                    switch (emailStore.get(id)) {
                        case (?email) {
                            if (not email.isReply) {
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
                            } else {// if reply exist show main head mail so when opened it will show full thread.df
                                switch (email.parentMailId) {
                                    case (?parentMailId) {
                                        switch (emailStore.get(parentMailId)) {
                                            case (?parentMail) {
                                                let responseEmail : T.EmailResponseDTO = {
                                                    id = parentMailId;
                                                    from = parentMail.from;
                                                    to = parentMail.to;
                                                    subject = parentMail.subject;
                                                    createdOn = parentMail.createdOn;
                                                    starred = false;
                                                    readFlag = false;
                                                };
                                                return ?responseEmail;

                                            };
                                            case null null;
                                        };
                                    };
                                    case null null;
                                };
                            };

                        }; // Extract the email if it exists
                        case null null; // Skip if the email is null
                    };
                },
            );

            // page number is optional, default pagination(pageNumber=1, pageSize=10)
            return getPaginatedEmails(caller, Option.get(pageNumber, 1), Option.get(pageSize, 10), emails, false);

        };

        //get list of sent mails
        public func fetchOutboxMails(caller : Principal, pageNumber : ?Nat, pageSize : ?Nat) : async [T.EmailResponseDTO] {

            //authenticate user when fetching the emails.
            let sentEmailIds : List.List<Text> = switch (registry.get(caller)) {
                //todo: add logic to only fetch latest mails and not whole list.
                case (?emailRegistry) emailRegistry.outbox;
                case null List.nil();
            };

            let emails = List.mapFilter<Text, T.EmailResponseDTO>(
                sentEmailIds,
                func(id) {
                    switch (emailStore.get(id)) {
                        case (?email) {
                            if (not email.isReply) {
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
                            } else {
                                return null;
                            }

                        }; // Extract the email if it exists
                        case null null; // Skip if the email is null
                    };
                },
            );

            // page number is optional, default pagination(pageNumber=1, pageSize=10)
            return getPaginatedEmails(caller, Option.get(pageNumber, 1), Option.get(pageSize, 10), emails, true);

        };

        private func getPaginatedEmails(caller : Principal, pageNumber : Nat, pageSize : Nat, emails : List.List<T.EmailResponseDTO>, isOutboxRequest : Bool) : [T.EmailResponseDTO] {

            // Safely decrements pageNumber (returns 0 if pageNumber is 0)
            let adjustedPageNumber : Nat = if (Nat.greater(pageNumber, 0)) {
                Nat.sub(pageNumber, 1);
            } else { 0 };

            let allEmails = List.toArray(emails);

            // Sort by createdAt (newest first)
            let sortedEmails = Array.sort(
                allEmails,
                func(a : T.EmailResponseDTO, b : T.EmailResponseDTO) : Order.Order {
                    Int.compare(b.createdOn, a.createdOn); // Descending order
                },
            );

            // Calculate pagination bounds
            let startIdx = adjustedPageNumber * pageSize;

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
                    let emailBaseDTO : T.EmailResponseDTO = {
                        email with
                        readFlag = readFlag;
                        starred = isStarred;
                    };

                    // let hasUnreadReplies : Bool = switch (threads.get(email.id)) {
                    //     case (?threadData) threadData.isNewMailAdded;
                    //     case null false;
                    // };

                    // let emailResponseDTO : T.Em = {
                    //     baseDto = emailBaseDTO;
                    //     // hasUnreadReplies = hasUnreadReplies;
                    // }

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

        public func getMailById(caller : Principal, emailId : Text) : Result.Result<[EmailQueries.EmailBodyResponseDTO], T.EmailErrors> {
            let savedEmail : ?T.Email = emailStore.get(emailId);
            switch (savedEmail) {
                case (?email) {
                    // Start building the full email thread response
                    var emailThreadIds : [Text] = switch (threads.get(emailId)) {
                        case (?thread) Array.append([thread.headMailId], thread.replyMailIds);
                        case null [emailId]; // fallback if thread not found
                    };

                    // Always include the main emailId at the front (in case not already included)
                    if (Array.find(emailThreadIds, func(id : Text) : Bool { id == emailId }) == null) {
                        emailThreadIds := Array.append([emailId], emailThreadIds);
                    };

                    let threadBuffer = Buffer.Buffer<EmailQueries.EmailBodyResponseDTO>(emailThreadIds.size());

                    for (id in emailThreadIds.vals()) {
                        switch (emailStore.get(id)) {
                            case (?threadEmail) {
                                let attachmentsBuffer = Buffer.Buffer<EmailQueries.FileResponseDTO>(threadEmail.attachmentIds.size());
                                for (fileId in threadEmail.attachmentIds.vals()) {
                                    switch (fileStore.get(fileId)) {
                                        case (?file) {
                                            attachmentsBuffer.add({
                                                fileId = fileId;
                                                fileName = file.fileName;
                                                size = file.size;
                                            });
                                        };
                                        case null {};
                                    };
                                };

                                let attachments : [EmailQueries.FileResponseDTO] = Buffer.toArray(attachmentsBuffer);

                                threadBuffer.add({
                                    id = id;
                                    from = threadEmail.from;
                                    to = threadEmail.to;
                                    subject = threadEmail.subject;
                                    body = threadEmail.body;
                                    attachments = ?attachments;
                                    createdOn = threadEmail.createdOn;
                                    starred = false;
                                    readFlag = true;
                                });

                                // Mark this email as read
                                markAsRead(caller, id);
                            };
                            case null {};
                        };
                    };

                    return #ok(Buffer.toArray(threadBuffer));
                };
                case null return #err(#NotFound);
            };
        };

        public func getThreadIds(headMailId : Text) : ?T.Thread {
            switch (threads.get(headMailId)) {
                case (?emailThread) ?emailThread;
                case null null;
            };
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
        //todo: add logic to delete threads as well along with mail.
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

        public func uploadFile(uploadedFile : EmailCommands.FileRequestDTO) : async Result.Result<EmailQueries.FileResponseDTO, T.FileErrors> {

            //generate new uuid key
            var uuidKey : Text = await utils.generateUUID();
            let file : T.File = {
                fileId = uuidKey;
                fileName = uploadedFile.fileName;
                contentType = uploadedFile.contentType;
                size = uploadedFile.filedata.size();
                filedata = uploadedFile.filedata;

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
