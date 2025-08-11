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

    // Helper function to get or create registry
    private func getOrCreateRegistry(principalId : Principal) : T.EmailRegistry {
      switch (registry.get(principalId)) {
        case (?reg) reg;
        case null {
          let newRegistry : T.EmailRegistry = {
            inbox = TrieMap.TrieMap<Text, Bool>(Text.equal, Text.hash);
            outbox = TrieMap.TrieMap<Text, Bool>(Text.equal, Text.hash);
            important = TrieMap.TrieMap<Text, Bool>(Text.equal, Text.hash);
            openedMails = TrieMap.TrieMap<Text, Bool>(Text.equal, Text.hash);
            draft = TrieMap.TrieMap<Text, Bool>(Text.equal, Text.hash);
            trash = TrieMap.TrieMap<Text, T.TrashMetaData>(Text.equal, Text.hash);
          };
          registry.put(principalId, newRegistry);
          newRegistry;
        };
      };
    };

    // Helper to update registry efficiently
    private func updateRegistry(principalId : Principal, mailId : Text, isInbox : Bool) {
      let reg = getOrCreateRegistry(principalId);
      if (isInbox) {
        reg.inbox.put(mailId, true);
      } else {
        reg.outbox.put(mailId, true);
      };
    };

    public func sendEmail(senderAddress : Text, senderPrincipalId : Principal, recipientPrinicpalId : Principal, mail : EmailCommands.SendEmailDTO) : async Result.Result<T.Email, T.EmailErrors> {
      if (senderAddress == mail.to) {
        return #err(#ErrorSelfTransfer);
      };

      if (mail.isReply and mail.parentMailId == null) {
        return #err(#MissingParentId);
      };

      let newMailId : Text = await utils.generateUUID();
      let parentMailId : ?Text = mail.parentMailId;

      let emailRequest : T.Email = {
        from = senderAddress;
        to = mail.to;
        subject = mail.subject;
        body = mail.body;
        attachmentIds = mail.attachmentIds;
        createdOn = Time.now();
        isReply = mail.isReply;
        parentMailId = parentMailId;
      };

      emailStore.put(newMailId, emailRequest);

      // Create thread if parent exists
      switch (parentMailId) {
        case (?pid) createThread(newMailId, pid);
        case null {};
      };

      // Update registries efficiently
      updateRegistry(senderPrincipalId, newMailId, false);
      updateRegistry(recipientPrinicpalId, newMailId, true);

      return #ok(emailRequest);
    };

    public func saveDraft(senderPrincipalId : Principal, mail : EmailCommands.SendEmailDTO) : async Result.Result<(), T.EmailErrors> {
      let emailId = await utils.generateUUID();
      let reg = getOrCreateRegistry(senderPrincipalId);

      let draftEmail : T.Email = {
        from = "";
        to = mail.to;
        subject = mail.subject;
        body = mail.body;
        attachmentIds = mail.attachmentIds;
        createdOn = Time.now();
        isReply = mail.isReply;
        parentMailId = mail.parentMailId;
      };

      emailStore.put(emailId, draftEmail);
      reg.draft.put(emailId, true);

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
            createdOn = existingDraft.createdOn;
            isReply = updatedMail.isReply;
            parentMailId = updatedMail.parentMailId;
          };

          emailStore.put(emailId, updatedDraft);
          return #ok();
        };
        case null return #err(#NotFound);
      };
    };

    public func deleteFromDrafts(user : Principal, draftId : Text) : async Result.Result<(), T.EmailErrors> {
      ignore emailStore.remove(draftId);

      switch (registry.get(user)) {
        case (?reg) {
          reg.draft.delete(draftId);
          return #ok();
        };
        case null return #err(#NotFound);
      };
    };

    public func createThread(mailId : Text, parentMailId : Text) : () {
      switch (threads.get(parentMailId)) {
        case (?existingThread) {
          let updatedReplyMailIdList : [Text] = Array.append(existingThread.replyMailIds, [mailId]);
          let updatedThread : T.Thread = {
            headMailId = existingThread.headMailId;
            replyMailIds = updatedReplyMailIdList;
            isNewMailAdded = true;
          };
          threads.put(parentMailId, updatedThread);
        };
        case null {
          let newThread : T.Thread = {
            headMailId = parentMailId;
            replyMailIds = [mailId];
            isNewMailAdded = true;
          };
          threads.put(parentMailId, newThread);
        };
      };
    };

    // Unified email fetching function to eliminate code duplication
    private func fetchEmailsByType(
      caller : Principal,
      emailType : Text,
      pageNumber : ?Nat,
      pageSize : ?Nat,
      isOutboxRequest : Bool,
    ) : async EmailQueries.PaginatedEmailBodyResponseDTO {

      let reg = getOrCreateRegistry(caller);
      let emailIds = switch (emailType) {
        case "inbox" reg.inbox;
        case "outbox" reg.outbox;
        case "important" reg.important;
        case "draft" reg.draft;
        case "trash" reg.trash;
        case _ return {
          currentPage = 1;
          pageSize = 10;
          totalItems = 0;
          totalPages = 0;
          data = [];
        };
      };

      let totalItems = emailIds.size();
      let emails = Buffer.Buffer<EmailQueries.EmailResponseDTO>(totalItems);

      // Process emails efficiently
      for ((emailId, _) in emailIds.entries()) {
        switch (emailStore.get(emailId)) {
          case (?email) {
            if (not email.isReply or emailType == "trash") {
              let responseEmail : EmailQueries.EmailResponseDTO = {
                id = emailId;
                from = email.from;
                to = email.to;
                preview = utils.subText(email.body, 0, 100);
                subject = Option.get(email.subject, noSubject);
                createdOn = email.createdOn;
                starred = emailType == "important";
                readFlag = isOutboxRequest or reg.openedMails.get(emailId) == ?true;
              };
              emails.add(responseEmail);
            };
          };
          case null {};
        };
      };

      let emailArray = Buffer.toArray(emails);

      // Sort by creation time (newest first)
      let sortedEmails = Array.sort(
        emailArray,
        func(a : EmailQueries.EmailResponseDTO, b : EmailQueries.EmailResponseDTO) : Order.Order {
          Int.compare(b.createdOn, a.createdOn);
        },
      );

      return getPaginatedEmails(
        caller,
        Option.get(pageNumber, 1),
        Option.get(pageSize, 10),
        totalItems,
        sortedEmails,
        isOutboxRequest,
      );
    };

    public func fetchInboxMails(caller : Principal, pageNumber : ?Nat, pageSize : ?Nat) : async EmailQueries.PaginatedEmailBodyResponseDTO {
      await fetchEmailsByType(caller, "inbox", pageNumber, pageSize, false);
    };

    public func fetchOutboxMails(caller : Principal, pageNumber : ?Nat, pageSize : ?Nat) : async EmailQueries.PaginatedEmailBodyResponseDTO {
      await fetchEmailsByType(caller, "outbox", pageNumber, pageSize, true);
    };

    public func fetchStarredMails(caller : Principal, pageNumber : ?Nat, pageSize : ?Nat) : async EmailQueries.PaginatedEmailBodyResponseDTO {
      await fetchEmailsByType(caller, "important", pageNumber, pageSize, false);
    };

    public func fetchDraftMails(caller : Principal, pageNumber : ?Nat, pageSize : ?Nat) : async EmailQueries.PaginatedEmailBodyResponseDTO {
      await fetchEmailsByType(caller, "draft", pageNumber, pageSize, false);
    };

    public func fetchTrashMails(caller : Principal, pageNumber : ?Nat, pageSize : ?Nat) : async EmailQueries.PaginatedEmailBodyResponseDTO {
      await fetchEmailsByType(caller, "trash", pageNumber, pageSize, false);
    };

    private func getPaginatedEmails(
      caller : Principal,
      pageNumber : Nat,
      pageSize : Nat,
      totalItemSize : Nat,
      sortedEmails : [EmailQueries.EmailResponseDTO],
      isOutboxRequest : Bool,
    ) : EmailQueries.PaginatedEmailBodyResponseDTO {

      let adjustedPageNumber = if (Nat.greater(pageNumber, 0)) Nat.sub(pageNumber, 1) else 0;
      let totalPages = if (pageSize == 0) 0 else (totalItemSize + pageSize - 1) / pageSize;
      let startIdx = adjustedPageNumber * pageSize;

      if (startIdx >= sortedEmails.size()) {
        return {
          currentPage = pageNumber;
          pageSize = pageSize;
          totalItems = totalItemSize;
          totalPages = totalPages;
          data = [];
        };
      };

      let safeEndIdx = Nat.min(startIdx + pageSize, sortedEmails.size());
      let paginatedEmails = Iter.toArray(Array.slice(sortedEmails, startIdx, safeEndIdx));

      // Process flags efficiently in a single pass
      let processedEmails = Array.map<EmailQueries.EmailResponseDTO, EmailQueries.EmailResponseDTO>(
        paginatedEmails,
        func(email) {
          let readFlag = if (isOutboxRequest) true else {
            switch (registry.get(caller)) {
              case (?reg) reg.openedMails.get(email.id) == ?true;
              case null false;
            };
          };

          let starred = switch (registry.get(caller)) {
            case (?reg) reg.important.get(email.id) == ?true;
            case null false;
          };

          {
            email with
            readFlag = readFlag;
            starred = starred;
          };
        },
      );

      {
        currentPage = pageNumber;
        pageSize = pageSize;
        totalItems = totalItemSize;
        totalPages = totalPages;
        data = processedEmails;
      };
    };

    public func markItAsImportant(caller : Principal, emailId : Text) : () {
      switch (registry.get(caller)) {
        case (?reg) reg.important.put(emailId, true);
        case null {};
      };
    };

    public func markAsNotImportant(caller : Principal, emailId : Text) : () {
      switch (registry.get(caller)) {
        case (?reg) reg.important.delete(emailId);
        case null {};
      };
    };

    public func markAsRead(caller : Principal, emailId : Text) : () {
      switch (registry.get(caller)) {
        case (?reg) reg.openedMails.put(emailId, true);
        case null {};
      };
    };

    public func markAsUnread(caller : Principal, emailId : Text) : () {
      switch (registry.get(caller)) {
        case (?reg) reg.openedMails.delete(emailId);
        case null {};
      };
    };

    public func deleteEmail(caller : Principal, emailId : Text) : () {
      switch (registry.get(caller)) {
        case (?reg) {
          let currentTime = Time.now();
          let tenDaysInNanos : Nat = 10 * 24 * 60 * 60 * 1_000_000_000;
          var sourceBucket : Text = "unknown";

          // Remove from appropriate buckets efficiently
          if (reg.inbox.get(emailId) == ?true) {
            reg.inbox.delete(emailId);
            sourceBucket := "inbox";
          };
          if (reg.outbox.get(emailId) == ?true) {
            reg.outbox.delete(emailId);
            sourceBucket := "outbox";
          };
          if (reg.draft.get(emailId) == ?true) {
            reg.draft.delete(emailId);
            sourceBucket := "draft";
          };

          if (sourceBucket == "unknown") return;

          // Get thread information
          let threadList : [Text] = switch (threads.get(emailId)) {
            case (?thread) thread.replyMailIds;
            case null [];
          };

          let trashEntry : T.TrashMetaData = {
            deleteAfter = currentTime + tenDaysInNanos;
            source = sourceBucket;
            threads = threadList;
          };

          reg.trash.put(emailId, trashEntry);
        };
        case null {};
      };
    };

    public func restoreEmail(caller : Principal, emailId : Text) : Result.Result<(), T.EmailErrors> {
      switch (registry.get(caller)) {
        case (?reg) {
          switch (reg.trash.get(emailId)) {
            case (?meta) {
              reg.trash.delete(emailId);

              switch (meta.source) {
                case "inbox" reg.inbox.put(emailId, true);
                case "outbox" reg.outbox.put(emailId, true);
                case "draft" reg.draft.put(emailId, true);
                case _ return #err(#UnknownSource);
              };

              return #ok();
            };
            case null return #err(#NotFound);
          };
        };
        case null return #err(#AnonymousCaller);
      };
    };

    public func getMailById(caller : Principal, emailId : Text) : Result.Result<[EmailQueries.EmailBodyResponseDTO], T.EmailErrors> {
      switch (emailStore.get(emailId)) {
        case null return #err(#NotFound);
        case (?email) {
          var emailThreadIds : [Text] = switch (threads.get(emailId)) {
            case (?thread) Array.append([thread.headMailId], thread.replyMailIds);
            case null [emailId];
          };

          if (Array.find(emailThreadIds, func(id : Text) : Bool { id == emailId }) == null) {
            emailThreadIds := Array.append([emailId], emailThreadIds);
          };

          let threadBuffer = Buffer.Buffer<EmailQueries.EmailBodyResponseDTO>(emailThreadIds.size());
          let reg = getOrCreateRegistry(caller);

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
                let isStarred = reg.important.get(id) == ?true;

                threadBuffer.add({
                  id = id;
                  from = threadEmail.from;
                  to = threadEmail.to;
                  subject = Option.get(threadEmail.subject, noSubject);
                  body = threadEmail.body;
                  attachments = ?attachments;
                  createdOn = threadEmail.createdOn;
                  starred = isStarred;
                  readFlag = true;
                });

                markAsRead(caller, id);
              };
              case null {};
            };
          };

          return #ok(Buffer.toArray(threadBuffer));
        };
      };
    };

    public func getThreadIds(headMailId : Text) : ?T.Thread {
      threads.get(headMailId);
    };

    public func deleteAllMails(caller : Principal) : () {
      registry.delete(caller);
    };

    // File handling methods
    public func uploadFile(uploadedFile : EmailCommands.FileRequestDTO) : async Result.Result<EmailQueries.FileResponseDTO, T.FileErrors> {
      let newFileId : Text = await utils.generateUUID();
      let file : T.File = {
        fileId = newFileId;
        fileName = uploadedFile.fileName;
        contentType = uploadedFile.contentType;
        size = uploadedFile.filedata.size();
        filedata = uploadedFile.filedata;
      };

      fileStore.put(newFileId, file);

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

    public func deleteFile(fileId : Text) : Result.Result<(), T.FileErrors> {
      switch (fileStore.remove(fileId)) {
        case (?_) #ok();
        case null #err(#NotFound);
      };
    };

    // Data persistence methods
    public func getStableEmailStore() : [(Text, T.Email)] {
      Iter.toArray(emailStore.entries());
    };

    public func setStableEmailStore(emails : [(Text, T.Email)]) : () {
      for (email in emails.vals()) {
        emailStore.put(email.0, email.1);
      };
    };

    public func getStableRegistries() : [(Principal, T.LegacyEmailRegistry)] {
      let result = Buffer.Buffer<(Principal, T.LegacyEmailRegistry)>(registry.size());

      for ((principal, reg) in registry.entries()) {
        let legacyReg : T.LegacyEmailRegistry = {
          inbox = List.fromArray(Iter.toArray(reg.inbox.keys()));
          outbox = List.fromArray(Iter.toArray(reg.outbox.keys()));
          important = List.fromArray(Iter.toArray(reg.important.keys()));
          openedMails = List.fromArray(Iter.toArray(reg.openedMails.keys()));
          draft = List.fromArray(Iter.toArray(reg.draft.keys()));
          trash = List.fromArray(Iter.toArray(reg.trash.entries()));
        };
        result.add((principal, legacyReg));
      };

      Buffer.toArray(result);
    };

    public func setStableRegistries(registries : [(Principal, T.LegacyEmailRegistry)]) : () {
      for ((principal, legacyReg) in registries.vals()) {
        let newReg : T.EmailRegistry = {
          inbox = TrieMap.TrieMap<Text, Bool>(Text.equal, Text.hash);
          outbox = TrieMap.TrieMap<Text, Bool>(Text.equal, Text.hash);
          important = TrieMap.TrieMap<Text, Bool>(Text.equal, Text.hash);
          openedMails = TrieMap.TrieMap<Text, Bool>(Text.equal, Text.hash);
          draft = TrieMap.TrieMap<Text, Bool>(Text.equal, Text.hash);
          trash = TrieMap.TrieMap<Text, T.TrashMetaData>(Text.equal, Text.hash);
        };

        // Convert legacy lists to maps

        for (id in List.toArray(legacyReg.inbox).vals()) {
          newReg.inbox.put(id, true);
        };
        for (id in List.toArray(legacyReg.outbox).vals()) {
          newReg.outbox.put(id, true);
        };
        for (id in List.toArray(legacyReg.important).vals()) {
          newReg.important.put(id, true);
        };
        for (id in List.toArray(legacyReg.openedMails).vals()) {
          newReg.openedMails.put(id, true);
        };
        for (id in List.toArray(legacyReg.draft).vals()) {
          newReg.draft.put(id, true);
        };
        for (entry in List.toArray(legacyReg.trash).vals()) {
          let (id, meta) = entry;
          newReg.trash.put(id, meta);
        };

        registry.put(principal, newReg);
      };
    };

    public func getStableFileStore() : [(Text, T.File)] {
      Iter.toArray(fileStore.entries());
    };

    public func setStableFileStore(files : [(Text, T.File)]) : () {
      for (file in files.vals()) {
        fileStore.put(file.0, file.1);
      };
    };

    public func getStableThreads() : [(Text, T.Thread)] {
      Iter.toArray(threads.entries());
    };

    public func setStableThreads(threadsMap : [(Text, T.Thread)]) : () {
      for (thread in threadsMap.vals()) {
        threads.put(thread.0, thread.1);
      };
    };

  };
};
