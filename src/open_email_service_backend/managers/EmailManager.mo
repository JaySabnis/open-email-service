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
import Debug "mo:base/Debug";

import Utils "../utils/helper";

import T "../types/EmailTypes";
import EmailCommands "../commands/EmailCommands";
import EmailQueries "../queries/EmailQueries";

module {

    public class EmailManager() {

        let utils = Utils.Utlis();

        let noSubject : Text = "(No Subject)";

        private var emailStore : TrieMap.TrieMap<Text, T.Email> = TrieMap.TrieMap<Text, T.Email>(Text.equal, Text.hash);
        private var fileStore : TrieMap.TrieMap<Text, T.File> = TrieMap.TrieMap<Text, T.File>(Text.equal, Text.hash);
        private var threads : TrieMap.TrieMap<Text, T.Thread> = TrieMap.TrieMap<Text, T.Thread>(Text.equal, Text.hash);
        private var registry : TrieMap.TrieMap<Principal, T.EmailRegistry> = TrieMap.TrieMap<Principal, T.EmailRegistry>(Principal.equal, Principal.hash);

        public func sendEmail(senderAddress : Text, senderPrincipalId : Principal, recipientPrinicpalId : Principal, mail : EmailCommands.SendEmailDTO) : async Result.Result<T.Email, T.EmailErrors> {
            //generate new uuid key
            var newMailId : Text = await utils.generateUUID();

            //determine if sender or reciver is valid
            if (senderAddress == mail.to) {
                return #err(#ErrorSelfTransfer);
            };

            if (mail.isReply and mail.parentMailId == null) { // consider checking empy strings as well.
                return #err(#MissingParentId);
            };

            let parentMailId : ?Text = mail.parentMailId;

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
            emailStore.put(newMailId, emailRequest);

            //create thread.// need to optimise the function.
            switch (parentMailId) {
                case (?pid) {
                    createThread(newMailId, pid); // only called if parentMailId exists
                };
                case null {};
            };

            // Add to sender's outbox
            updateRegistry(senderPrincipalId, newMailId, false);

            // Add to recipient's inbox
            updateRegistry(recipientPrinicpalId, newMailId, true);

            return #ok(emailRequest);
        };

        // Helper to update or create EmailRegistry
        func updateRegistry(principalId : Principal, mailId : Text, isInbox : Bool) {
            let currentRegistry = registry.get(principalId);
            let newRegistry : T.EmailRegistry = switch (currentRegistry) {
                case (?reg) {
                    {
                        inbox = if (isInbox) List.push(mailId, reg.inbox) else reg.inbox;
                        outbox = if (not isInbox) List.push(mailId, reg.outbox) else reg.outbox;
                        important = reg.important;
                        openedMails = reg.openedMails;
                        draft = reg.draft;
                        trash = reg.trash;
                    };
                };
                case null {
                    {
                        inbox = if (isInbox) List.push(mailId, List.nil()) else List.nil();
                        outbox = if (not isInbox) List.push(mailId, List.nil()) else List.nil();
                        important = List.nil();
                        openedMails = List.nil();
                        draft = List.nil(); //todo check logic , user can save email before sending email.
                        trash = List.nil();

                    };
                };
            };
            registry.put(principalId, newRegistry);
        };

        public func saveDraft(senderPrincipalId : Principal, mail : EmailCommands.SendEmailDTO) : async Result.Result<(), T.EmailErrors> {
            // generate new UUID
            let emailId = await utils.generateUUID();

            // create draft email with empty from/to
            let draftEmail : T.Email = {
                from = ""; // do not store sender in draft
                to = mail.to; 
                subject = mail.subject;
                body = mail.body;
                attachmentIds = mail.attachmentIds;
                createdOn = Time.now();
                isReply = mail.isReply;
                parentMailId = mail.parentMailId;
            };

            // store in email store
            emailStore.put(emailId, draftEmail);

            // update registry drafts
            updateDraftRegistry(senderPrincipalId, emailId);

            return #ok();
        };

        public func editDraft(emailId : Text, updatedMail : EmailCommands.SendEmailDTO) : async Result.Result<(), T.EmailErrors> {
            switch (emailStore.get(emailId)) {
                case (?existingDraft) {
                    let updatedDraft : T.Email = {
                        from = "";
                        to = updatedMail.to;
                        subject = updatedMail.subject;
                        body = updatedMail.body;
                        attachmentIds = updatedMail.attachmentIds;
                        createdOn = existingDraft.createdOn; // preserve original creation time
                        isReply = updatedMail.isReply;
                        parentMailId = updatedMail.parentMailId;
                    };

                    emailStore.put(emailId, updatedDraft);
                    return #ok();
                };
                case null {
                    return #err(#NotFound);
                };
            };
        };

        func updateDraftRegistry(principalId : Principal, draftId : Text) {
            let currentRegistry = registry.get(principalId);
            let newRegistry : T.EmailRegistry = switch (currentRegistry) {
                case (?reg) {
                    {
                        inbox = reg.inbox;
                        outbox = reg.outbox;
                        important = reg.important;
                        openedMails = reg.openedMails;
                        draft = List.push(draftId, reg.draft);
                        trash = reg.trash;
                    };
                };
                case null {
                    {
                        inbox = List.nil();
                        outbox = List.nil();
                        important = List.nil();
                        openedMails = List.nil();
                        draft = List.push(draftId, List.nil()); // create with only the draft
                        trash = List.nil();
                    };
                };
            };
            registry.put(principalId, newRegistry);
        };

        public func deleteFromDrafts(user : Principal, draftId : Text) : async Result.Result<(), T.EmailErrors> {
            // Remove from emailStore
            ignore emailStore.remove(draftId);

            // Update user's registry to remove the draftId from their draft list
            switch (registry.get(user)) {
                case (?reg) {
                    let updatedDrafts = List.filter<Text>(
                        reg.draft,
                        func(id : Text) : Bool {
                            id != draftId;
                        },
                    );

                    let updatedRegistry : T.EmailRegistry = {
                        inbox = reg.inbox;
                        outbox = reg.outbox;
                        important = reg.important;
                        openedMails = reg.openedMails;
                        draft = updatedDrafts;
                        trash = reg.trash;
                    };

                    registry.put(user, updatedRegistry);
                };
                case null {
                    return #err(#NotFound);
                };
            };

            return #ok(());
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
        public func fetchInboxMails(caller : Principal, pageNumber : ?Nat, pageSize : ?Nat) : async EmailQueries.PaginatedEmailBodyResponseDTO {
            //authenticate user when fetching the emails.
            let receviedEmailIds : List.List<Text> = switch (registry.get(caller)) {
                case (?emailRegistry) emailRegistry.inbox;
                case null List.nil();
            };

            let totalItems : Nat = List.size(receviedEmailIds);

            // todo:instead of fetching all mails just fetch latest mails
            let emails = List.mapFilter<Text, EmailQueries.EmailResponseDTO>(
                receviedEmailIds,
                func(id) {
                    switch (emailStore.get(id)) {
                        case (?email) {
                            // Extract the email if it exists.
                            if (not email.isReply) {
                                let responseEmail : EmailQueries.EmailResponseDTO = {
                                    id = id;
                                    from = email.from;
                                    to = email.to;
                                    preview = utils.subText(email.body, 0, 100);
                                    subject = Option.get(email.subject, noSubject);
                                    createdOn = email.createdOn;
                                    starred = false;
                                    readFlag = false;
                                };
                                return ?responseEmail;

                            } else {
                                // if reply exist show main head mail so when opened it will show full thread.
                                switch (email.parentMailId) {
                                    case (?parentMailId) {
                                        switch (emailStore.get(parentMailId)) {
                                            case (?parentMail) {
                                                let responseEmail : EmailQueries.EmailResponseDTO = {
                                                    id = parentMailId;
                                                    from = email.from;
                                                    to = email.to;
                                                    preview = utils.subText(email.body, 0, 100);
                                                    subject = Text.concat("RE: [Follow-up on earlier email] ", Option.get(parentMail.subject, noSubject));
                                                    createdOn = parentMail.createdOn;
                                                    starred = false;
                                                    readFlag = false;
                                                };
                                                return ?responseEmail;

                                            };
                                            case null {
                                                Debug.print("⚠️ Parent mail with ID " # parentMailId # " not found in store.");
                                                return null;
                                            };
                                        };
                                    };
                                    case null {
                                        Debug.print("⚠️ Reply mail " # id # " does not have a parentMailId.");
                                        return null;
                                    };
                                };
                            };

                        };

                        case null {
                            // Skip if the email is null
                            Debug.print("⚠️ Email with ID " # id # " not found in store.");
                            return null;
                        };
                    };
                },
            );

            // page number is optional, default pagination(pageNumber=1, pageSize=10)
            return getPaginatedEmails(caller, Option.get(pageNumber, 1), Option.get(pageSize, 10), totalItems, emails, false);

        };

        //get list of sent mails
        public func fetchOutboxMails(caller : Principal, pageNumber : ?Nat, pageSize : ?Nat) : async EmailQueries.PaginatedEmailBodyResponseDTO {

            //authenticate user when fetching the emails.
            let sentEmailIds : List.List<Text> = switch (registry.get(caller)) {
                //todo: add logic to only fetch latest mails and not whole list.
                case (?emailRegistry) emailRegistry.outbox;
                case null List.nil();
            };

            let totalItems : Nat = List.size(sentEmailIds);

            let emails = List.mapFilter<Text, EmailQueries.EmailResponseDTO>(
                sentEmailIds,
                func(id) {
                    switch (emailStore.get(id)) {
                        case (?email) {
                            if (not email.isReply) {
                                let responseEmail : EmailQueries.EmailResponseDTO = {
                                    id = id;
                                    from = email.from;
                                    to = email.to;
                                    preview = utils.subText(email.body, 0, 100);
                                    subject = Option.get(email.subject, noSubject);
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
            return getPaginatedEmails(caller, Option.get(pageNumber, 1), Option.get(pageSize, 10), totalItems, emails, true);

        };

        //get list of sent mails
        public func fetchStarredMails(caller : Principal, pageNumber : ?Nat, pageSize : ?Nat) : async EmailQueries.PaginatedEmailBodyResponseDTO {

            //authenticate user when fetching the emails.
            let starredEmailIds : List.List<Text> = switch (registry.get(caller)) {
                //todo: add logic to only fetch latest mails and not whole list.
                case (?emailRegistry) emailRegistry.important;
                case null List.nil();
            };

            let totalItems : Nat = List.size(starredEmailIds);

            let emails = List.mapFilter<Text, EmailQueries.EmailResponseDTO>(
                starredEmailIds,
                func(id) {
                    switch (emailStore.get(id)) {
                        case (?email) {
                            if (not email.isReply) {
                                let responseEmail : EmailQueries.EmailResponseDTO = {
                                    id = id;
                                    from = email.from;
                                    to = email.to;
                                    preview = utils.subText(email.body, 0, 100);
                                    subject = Option.get(email.subject, noSubject);
                                    createdOn = email.createdOn;
                                    starred = true;
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
            return getPaginatedEmails(caller, Option.get(pageNumber, 1), Option.get(pageSize, 10), totalItems, emails, true);

        };

        //todo: create one fuction and reuse the logic of fetch email with type instead of calling seprate fucntion for all 5 different types.
        public func fetchDraftMails(caller : Principal, pageNumber : ?Nat, pageSize : ?Nat) : async EmailQueries.PaginatedEmailBodyResponseDTO {

            //authenticate user when fetching the emails.
            let sentEmailIds : List.List<Text> = switch (registry.get(caller)) {
                //todo: add logic to only fetch latest mails and not whole list.
                case (?emailRegistry) emailRegistry.draft;
                case null List.nil();
            };

            let totalItems : Nat = List.size(sentEmailIds);

            let emails = List.mapFilter<Text, EmailQueries.EmailResponseDTO>(
                sentEmailIds,
                func(id) {
                    switch (emailStore.get(id)) {
                        case (?email) {
                            if (not email.isReply) {
                                let responseEmail : EmailQueries.EmailResponseDTO = {
                                    id = id;
                                    from = email.from;
                                    to = email.to;
                                    preview = utils.subText(email.body, 0, 100);
                                    subject = Option.get(email.subject, noSubject);
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
            return getPaginatedEmails(caller, Option.get(pageNumber, 1), Option.get(pageSize, 10), totalItems, emails, true);

        };

        private func getPaginatedEmails(caller : Principal, pageNumber : Nat, pageSize : Nat, totalItemSize : Nat, emails : List.List<EmailQueries.EmailResponseDTO>, isOutboxRequest : Bool) : EmailQueries.PaginatedEmailBodyResponseDTO {

            // Safely decrements pageNumber (returns 0 if pageNumber is 0)
            let adjustedPageNumber : Nat = if (Nat.greater(pageNumber, 0)) {
                Nat.sub(pageNumber, 1);
            } else { 0 };

            let allEmails = List.toArray(emails);

            // Sort by createdAt (newest first)
            let sortedEmails = Array.sort(
                allEmails,
                func(a : EmailQueries.EmailResponseDTO, b : EmailQueries.EmailResponseDTO) : Order.Order {
                    Int.compare(b.createdOn, a.createdOn); // Descending order
                },
            );

            let totalItems = totalItemSize;
            let totalPages = if (pageSize == 0) { 0 } else {
                (totalItems + pageSize - 1) / pageSize;
            };

            // Calculate pagination bounds
            let startIdx = adjustedPageNumber * pageSize;

            // Handle case where start index is beyond array bounds
            if (startIdx >= sortedEmails.size()) {
                return {
                    currentPage = pageNumber;
                    pageSize = pageSize;
                    totalItems = totalItems;
                    totalPages = totalPages;
                    data = [];
                };
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
            let processedEmails = Array.map<EmailQueries.EmailResponseDTO, EmailQueries.EmailResponseDTO>(
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

                    {
                        email with
                        readFlag = readFlag;
                        starred = isStarred;
                    };

                },
            );

            {
                currentPage = pageNumber;
                pageSize = pageSize;
                totalItems = totalItems;
                totalPages = totalPages;
                data = processedEmails;
            };
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
                        openedMails = savedRecord.openedMails;
                        draft = savedRecord.draft;
                        trash = savedRecord.trash;
                    };

                    //add updated records.
                    registry.put(caller, updatedRegistry);
                };
                case null return;
            };

        };

        public func markAsNotImportant(caller : Principal, emailId : Text) : () {
            switch (registry.get(caller)) {
                case null return;
                case (?record) {
                    let updatedRegistry : T.EmailRegistry = {
                        inbox = record.inbox;
                        outbox = record.outbox;
                        important = List.filter<Text>(record.important, func(id : Text) : Bool { id != emailId });
                        openedMails = record.openedMails;
                        draft = record.draft;
                        trash = record.trash;
                    };
                    registry.put(caller, updatedRegistry);
                };
            };
        };

        public func getMailById(caller : Principal, emailId : Text) : Result.Result<[EmailQueries.EmailBodyResponseDTO], T.EmailErrors> {
            let savedEmail : ?T.Email = emailStore.get(emailId);
            switch (savedEmail) {
                case null return #err(#NotFound);

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

                    //get starred email
                    let importantMailsList : List.List<Text> = getImportantMailList(caller);

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

                                // Check if the current email ID exists in the importantMailsList
                                let isStarred = switch (List.find<Text>(importantMailsList, func(listId) { listId == id })) {
                                    case (?_) true;
                                    case null false;
                                };

                                threadBuffer.add({
                                    id = id;
                                    from = threadEmail.from;
                                    to = threadEmail.to;
                                    subject = Option.get(threadEmail.subject, noSubject);
                                    body = threadEmail.body;
                                    attachments = ?attachments;
                                    createdOn = threadEmail.createdOn;
                                    starred = isStarred;
                                    readFlag = true;//true
                                });

                                //once mail is opened mark it as read.
                                markAsRead(caller,id);
                            };
                            case null {};
                        };
                    };

                    return #ok(Buffer.toArray(threadBuffer));
                };
            };
        };

        public func getThreadIds(headMailId : Text) : ?T.Thread {
            switch (threads.get(headMailId)) {
                case (?emailThread) ?emailThread;
                case null null;
            };
        };

        // Mark email as read
        public func markAsRead(caller : Principal, emailId : Text) : () {
            switch (registry.get(caller)) {
                case (?record) {
                    let updatedOpened = List.push(emailId, record.openedMails);

                    let updatedRegistry : T.EmailRegistry = {
                        inbox = record.inbox;
                        outbox = record.outbox;
                        important = record.important;
                        openedMails = updatedOpened;
                        draft = record.draft;
                        trash = record.trash;
                    };

                    registry.put(caller, updatedRegistry);
                };
                case null return;
            };
        };

        // Mark email as unread
        public func markAsUnread(caller : Principal, emailId : Text) : () {
            switch (registry.get(caller)) {
                case (?record) {
                    let updatedOpened = List.filter<Text>(
                        record.openedMails,
                        func(id : Text) : Bool { id != emailId },
                    );

                    let updatedRegistry : T.EmailRegistry = {
                        inbox = record.inbox;
                        outbox = record.outbox;
                        important = record.important;
                        openedMails = updatedOpened;
                        draft = record.draft;
                        trash = record.trash;
                    };

                    registry.put(caller, updatedRegistry);
                };
                case null return;
            };
        };

        //delete E-mail by id.
        public func deleteEmail(caller : Principal, emailId : Text) : () {
            switch (registry.get(caller)) {
                case null return;
                case (?record) {
                    let currentTime = Time.now();
                    let tenDaysInNanos : Nat = 10 * 24 * 60 * 60 * 1_000_000_000;

                    var sourceBucket : Text = "unknown";

                    // Only remove from inbox and outbox
                    let remove = func(list : List.List<Text>, bucket : Text) : (List.List<Text>, Bool) {
                        var found = false;
                        let updated = List.filter<Text>(
                            list,
                            func(id : Text) : Bool {
                                if (id == emailId) {
                                    found := true; // update flag
                                    false; //return false so that id can be skipped and removed..
                                } else true;
                            },
                        );

                        if (found) sourceBucket := bucket;

                        return (updated, found);
                    };

                    let (inboxList, _) = remove(record.inbox, "inbox");
                    let (outboxList, _) = remove(record.outbox, "outbox");
                    let (draftList, _) = remove(record.draft, "draft");

                    if (sourceBucket == "unknown") return; // Skip if not in inbox/outbox

                    let threadList : [Text] = switch (threads.get(emailId)) {
                        case (?thread) thread.replyMailIds;
                        case null [];
                    };

                    let trashEntry : T.TrashMetaData = {
                        deleteAfter = currentTime + tenDaysInNanos;
                        source = sourceBucket;
                        threads = threadList;
                    };

                    let updateTrashList : List.List<(Text, T.TrashMetaData)> = List.append(record.trash, List.make((emailId, trashEntry)));

                    let updatedRegistry : T.EmailRegistry = {
                        inbox = inboxList;
                        outbox = outboxList;
                        important = record.important;
                        openedMails = record.openedMails;
                        draft = draftList;
                        trash = updateTrashList;
                    };

                    registry.put(caller, updatedRegistry);
                };
            };
        };

        public func restoreEmail(caller : Principal, emailId : Text) : Result.Result<(), T.EmailErrors> {
            switch (registry.get(caller)) {
                case null return #err(#AnonymousCaller);
                case (?record) {
                    // Search for the trash entry
                    var foundMeta : ?T.TrashMetaData = null;

                    let filteredTrash = List.filter<(Text, T.TrashMetaData)>(
                        record.trash,
                        func(pair : (Text, T.TrashMetaData)) : Bool {
                            let (id, meta) = pair;
                            if (id == emailId) {
                                foundMeta := ?meta;
                                return false; // filter out (i.e., remove) the matched entry
                            };
                            true;
                        },
                    );

                    switch (foundMeta) {
                        case null return #err(#NotFound);
                        case (?meta) {
                            var inboxList = record.inbox;
                            var outboxList = record.outbox;
                            var draftList = record.draft;

                            if (meta.source == "inbox") {
                                inboxList := List.push(emailId, inboxList);
                            } else if (meta.source == "outbox") {
                                outboxList := List.push(emailId, outboxList);
                            } else if (meta.source == "draft") {
                                draftList := List.push(emailId, draftList);
                            } else return #err(#UnknownSource);

                            let updatedRegistry : T.EmailRegistry = {
                                inbox = inboxList;
                                outbox = outboxList;
                                important = record.important;
                                openedMails = record.openedMails;
                                draft = record.draft;
                                trash = filteredTrash;
                            };

                            registry.put(caller, updatedRegistry);
                            return #ok();
                        };
                    };
                };
            };
        };

        // get list of trash mails
        public func fetchTrashMails(caller : Principal, pageNumber : ?Nat, pageSize : ?Nat) : async EmailQueries.PaginatedEmailBodyResponseDTO {

            let trashList : List.List<(Text, T.TrashMetaData)> = switch (registry.get(caller)) {
                case (?emailRegistry) emailRegistry.trash;
                case null List.nil();
            };

            let totalItems : Nat = List.size(trashList);

            let emails = List.mapFilter<(Text, T.TrashMetaData), EmailQueries.EmailResponseDTO>(
                trashList,
                func(pair) {
                    let (id, _) = pair;

                    switch (emailStore.get(id)) {
                        case (?email) {
                            if (not email.isReply) {
                                let responseEmail : EmailQueries.EmailResponseDTO = {
                                    id = id;
                                    from = email.from;
                                    to = email.to;
                                    preview = utils.subText(email.body, 0, 100);
                                    subject = Option.get(email.subject, noSubject);
                                    createdOn = email.createdOn;
                                    starred = false;
                                    readFlag = false;
                                };

                                return ?responseEmail;
                            } else {
                                return null;
                            };
                        };
                        case null null;
                    };
                },
            );

            return getPaginatedEmails(caller, Option.get(pageNumber, 1), Option.get(pageSize, 10), totalItems, emails, false);
        };

        //delete all mails for the caller while deleting the profile.
        //todo: add logic to delete threads as well along with mail.
        public func deleteAllMails(caller : Principal) : () {
            switch (registry.get(caller)) {
                case (?_) registry.delete(caller);
                case null return;
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

        // ───────────────────────────────────────────────
        // 🎞️ Multimedia File Handling
        // ───────────────────────────────────────────────
        // The following methods are responsible for handling
        // multimedia file operations such as uploading files,
        // storing them and retrieving them
        // when needed.
        // ───────────────────────────────────────────────

        //Multimedia file handling methods.
        public func uploadFile(uploadedFile : EmailCommands.FileRequestDTO) : async Result.Result<EmailQueries.FileResponseDTO, T.FileErrors> {

            //generate new uuid key
            var newFileId : Text = await utils.generateUUID();
            let file : T.File = {
                fileId = newFileId;
                fileName = uploadedFile.fileName;
                contentType = uploadedFile.contentType;
                size = uploadedFile.filedata.size();
                filedata = uploadedFile.filedata;

            };
            fileStore.put(newFileId, file);

            //validate if operation is successfull or not
            switch (fileStore.get(newFileId)) {
                case (?savedResponse) #ok({
                    fileId = newFileId;
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

        // ===============================
        // 📦 Data Persistence Section
        // ===============================
        // This section handles accessing and updating email data from stable variables,
        // ensuring inbox and outbox states are correctly persisted for each user.
        // ===============================

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

        public func getStableThreads() : [(Text, T.Thread)] {
            return Iter.toArray(threads.entries());
        };

        public func setStableThreads(threadsMap : [(Text, T.Thread)]) : () {
            for (entry in Iter.fromArray(threadsMap)) {
                threads.put(entry.0, entry.1);
            };
        };

    };
};
