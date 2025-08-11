<script>
  import { createEventDispatcher } from "svelte";
  import { theme } from "$lib/store/theme";
  import { get } from "svelte/store";
  import { faTrashAlt,faPencilAlt } from "@fortawesome/free-solid-svg-icons";
  import { FontAwesomeIcon } from "@fortawesome/svelte-fontawesome";
  import { faRotateLeft } from "@fortawesome/free-solid-svg-icons";
  import { profileStore } from "$lib/store/profile-store";
  import { generateImageSrc, formatFileSize } from "$lib/utils/helpers";
  import { mailsStore } from "$lib/store/mails-store";
  import { showLoader, hideLoader } from "$lib/store/loader-store";
  import WriteMail from "./WriteMail.svelte";
  import { fade, fly } from "svelte/transition";
  import { quintOut } from "svelte/easing";
  import {getMails} from "$lib/utils/CommonApi";
  import ConfirmationDialogue from "./ConfirmationDialogue.svelte";
  import { goto } from '$app/navigation';
  
  export let message;
  export let isFirst = false;
  export let pageType = "inbox";

  const dispatch = createEventDispatcher();
  let currentTheme = get(theme);
  let showReplyModal = false;
  let showDeleteConfirmation = false;
  let fromUser = null;
  let isOpen = isFirst;
  export let close;
  let showEditModal = false;
  

  async function getFromUser() {
    try {
      const fromUserResponse = await profileStore.getProfileByUserAddress(
        message.from
      );
      fromUser = fromUserResponse?.ok || null;

      if (!fromUser) {
        try {
          const currentUserResponse = await profileStore.getProfile();
          fromUser = currentUserResponse?.ok || null;
        } catch (err) {
          console.error("Error fetching current user profile:", err);
        }
      }
    } catch (err) {
      console.error("Error fetching from user:", err);
    }
  }

  async function fetchMails() {
    try {
      showLoader('Loading Mails...');
      const result = await getMails(pageType, 1, 10);
    } catch (err) {
      console.error("Error in component while fetching mails:", err);
    } finally {
      hideLoader();
    }
  }

  function handleReply() {
    showReplyModal = true;
  }

  function handleSendReply(event) {
    showReplyModal = false;
    dispatch("refresh");
  }

   function handleEdit() {
    showEditModal = true;
  }

  function handleEditComplete(event) {
    showEditModal = false;
    dispatch("refresh");
  }

  async function handleDelete(messageId) {
    // console.log("Deleting message with ID:", messageId);
    if (!messageId) return;

    try {
      showLoader("Deleting mail...");
      await mailsStore.deleteEmail(messageId);
      close();
      window.location.reload();
      // await fetchMails();
    } catch (err) {
      console.error("Failed to delete mail:", err);
    } finally {
      hideLoader();
    }
  }

  async function handleRestore(messageId) {
    if (!messageId) return;

    try {
      showLoader("Restoring Mail...");
      await mailsStore.restoreEmail(messageId);
      close();
      window.location.reload();
      // await fetchMails();
    } catch (err) {
      console.error("Failed to restore mail:", err);
    } finally {
      hideLoader();
    }
  }

  function handleDeleteClick() {
    showDeleteConfirmation = true;
  }

  function handleDeleteConfirm() {
    showDeleteConfirmation = false;
    // console.log("Confirmed delete for message:", message?.id);
    handleDelete(message?.id);
  }

  async function markAsImportant(msgId) {
    try {
      showLoader("Marking important...");
      const msg = await mailsStore.markItAsImportant(msgId);
      // window.location.reload();
    } catch (err) {
      console.error("Failed to mark as important", error);
      error = err;
    } finally {
      hideLoader();
    }
  }

  async function markAsNotImportant(msgId) {
    try {
      showLoader("Marking as Unimportant...");
      const msg = await mailsStore.markAsNotImportant(msgId);
      // window.location.reload();
    } catch (err) {
      console.error("Failed to mark as unimportant", error);
      error = err;
    } finally {
      hideLoader();
    }
  }

  $: if (message) {
    getFromUser();
  }
</script>

<div
  class="border rounded-lg mb-3 overflow-hidden transition-all duration-200 ease-out"
  class:border-gray-200={currentTheme === "light"}
  class:border-gray-700={currentTheme === "dark"}
  class:shadow-md={isOpen}
  class:shadow={!isOpen}
>
  <div
    class="p-4 cursor-pointer flex justify-between items-start hover:bg-opacity-50 transition-colors duration-200"
    on:click={() => (isOpen = !isOpen)}
    class:bg-gray-50={currentTheme === "light" && isOpen}
    class:bg-gray-800={currentTheme === "dark" && isOpen}
    class:hover:bg-gray-100={currentTheme === "light"}
    class:hover:bg-gray-700={currentTheme === "dark"}
  >
    <div class="flex items-start gap-3 flex-1 min-w-0">
      {#if fromUser?.profileImage}
        <img
          src={generateImageSrc(fromUser.profileImage)}
          alt="Profile Image"
          class="w-10 h-10 rounded-full object-cover border flex-shrink-0 mt-1"
          class:border-gray-300={currentTheme === "light"}
          class:border-gray-600={currentTheme === "dark"}
        />
      {:else}
        <div
          class="w-10 h-10 rounded-full bg-gray-200 flex items-center justify-center flex-shrink-0 mt-1"
          class:bg-gray-700={currentTheme === "dark"}
        >
          <span
            class="text-lg font-medium"
            class:text-gray-600={currentTheme === "light"}
            class:text-gray-300={currentTheme === "dark"}
          >
            {(fromUser?.name || message?.from || "?").charAt(0).toUpperCase()}
          </span>
        </div>
      {/if}

      <div class="min-w-0">
        <div class="flex items-baseline flex-wrap gap-1">
          <span
            class="font-medium truncate"
            class:text-gray-800={currentTheme === "light"}
            class:text-gray-200={currentTheme === "dark"}
          >
            {fromUser?.name || ""}
            {fromUser?.surname || ""}
          </span>

          <span
            class="text-xs truncate"
            class:text-gray-500={currentTheme === "light"}
            class:text-gray-400={currentTheme === "dark"}
          >
            &lt;{message?.from || fromUser?.userAddress}&gt;
          </span>

          <span
            class="text-xs ml-2"
            class:text-gray-500={currentTheme === "light"}
            class:text-gray-400={currentTheme === "dark"}
          >
            {new Date(Number(message?.createdOn) / 1_000_000).toLocaleString()}
          </span>
        </div>

        {#if !message?.parentMailId}
          <div class="text-sm font-medium line-clamp-1 mt-1"
               class:text-gray-700={currentTheme === "light"}
               class:text-gray-300={currentTheme === "dark"}>
            {message?.subject || ""}
          </div>
        {/if}

        {#if isOpen}
          <div
            class="text-xs mt-2"
            class:text-gray-600={currentTheme === "light"}
            class:text-gray-400={currentTheme === "dark"}
          >
            <span class="font-medium">To:</span>
            {message?.to || "N/A"}
          </div>
        {/if}
      </div>
    </div>

    <div class="flex items-center gap-2 ml-2 flex-shrink-0">
      {#if isOpen}
        {#if pageType !== "draft"}
          <div
            class="cursor-pointer text-yellow-500"
            on:click|stopPropagation={pageType !== "trash" &&
            pageType !== "draft"
              ? () =>
                  message?.starred
                    ? markAsNotImportant(message?.id)
                    : markAsImportant(message?.id)
              : null}
          >
            {#if message?.starred}
              ★
            {:else}
              ☆
            {/if}
          </div>
        {/if}

        {#if pageType !== "trash" && pageType !== "draft"}
          <button
            class="p-2 rounded-full hover:bg-opacity-20 transition-colors"
            on:click|stopPropagation={handleReply}
            class:hover:bg-blue-500={currentTheme === "light"}
            class:hover:bg-blue-600={currentTheme === "dark"}
            title="Reply"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              class:text-gray-600={currentTheme === "light"}
              class:text-gray-400={currentTheme === "dark"}
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6"
              />
            </svg>
          </button>
        {/if}

        {#if pageType !== "trash"}
          <button
            class="p-2 rounded-full hover:bg-opacity-20 transition-colors"
            on:click|stopPropagation={handleDeleteClick}
            class:hover:bg-red-500={currentTheme === "light"}
            class:hover:bg-red-600={currentTheme === "dark"}
            title="Delete"
          >
            <span
              class:text-gray-600={currentTheme === "light"}
              class:text-gray-400={currentTheme === "dark"}
            >
              <FontAwesomeIcon icon={faTrashAlt} class="h-4 w-4" />
            </span>
          </button>
        {/if}

        {#if pageType == "draft"}
        <button
          class="p-2 rounded-full hover:bg-opacity-20 transition-colors"
          on:click|stopPropagation={handleEdit}
          class:hover:bg-blue-500={currentTheme === "light"}
          class:hover:bg-blue-600={currentTheme === "dark"}
          title="Edit"
        >
          <span
            class:text-gray-600={currentTheme === "light"}
            class:text-gray-400={currentTheme === "dark"}
          >
            <FontAwesomeIcon icon={faPencilAlt} class="h-4 w-4" />
          </span>
        </button>
      {/if}

        {#if pageType === "trash"}
          <button
            class="p-2 rounded-full hover:bg-opacity-20 transition-colors"
            on:click|stopPropagation={() => handleRestore(message.id)}
            class:hover:bg-green-500={currentTheme === "light"}
            class:hover:bg-green-600={currentTheme === "dark"}
            title="Restore"
          >
            <span
              class:text-gray-600={currentTheme === "light"}
              class:text-gray-400={currentTheme === "dark"}
            >
              <FontAwesomeIcon icon={faRotateLeft} class="h-4 w-4" />
            </span>
          </button>
        {/if}
      {:else if pageType !== "draft"}
        <div
          class="cursor-pointer text-yellow-500"
          on:click|stopPropagation={pageType !== "trash" && pageType !== "draft"
            ? () =>
                message?.starred
                  ? markAsNotImportant(message?.id)
                  : markAsImportant(message?.id)
            : null}
        >
          {#if message?.starred}
            ★
          {:else}
            ☆
          {/if}
        </div>
      {/if}

      <div
        class={`w-5 h-5 flex items-center justify-center transition-transform duration-200 ${isOpen ? "rotate-180" : ""}`}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-4 w-4"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          class:text-gray-500={currentTheme === "light"}
          class:text-gray-400={currentTheme === "dark"}
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M19 9l-7 7-7-7"
          />
        </svg>
      </div>
    </div>
  </div>

  {#if isOpen}
    <div
      transition:fly={{ y: -10, duration: 200, easing: quintOut }}
      class="p-4 border-t"
      class:border-gray-200={currentTheme === "light"}
      class:border-gray-700={currentTheme === "dark"}
      class:bg-white={currentTheme === "light"}
      class:bg-gray-900={currentTheme === "dark"}
    >
      <div
        class="whitespace-pre-line text-sm leading-relaxed"
        class:text-gray-800={currentTheme === "light"}
        class:text-gray-200={currentTheme === "dark"}
      >
        {message?.body || "No content"}
      </div>

      {#if message?.attachments?.filter(a => a[0]?.fileId).length > 0}
        <div
          class="mt-4 pt-4 border-t"
          class:border-gray-200={currentTheme === "light"}
          class:border-gray-700={currentTheme === "dark"}
        >
          <h4
            class="text-sm font-medium mb-2"
            class:text-gray-700={currentTheme === "light"}
            class:text-gray-300={currentTheme === "dark"}
          >
            Attachments ({message.attachments.filter(a => a[0]?.fileId).length})
          </h4>

          <div class="grid gap-2">
            {#each message.attachments as attachment}
              {#if attachment[0]?.fileId}
                {#await mailsStore.getFileById(attachment[0].fileId) then fileResponse}
                  {#if fileResponse?.ok}
                    <div
                      class="flex items-center gap-3 p-2 rounded border"
                      class:border-gray-200={currentTheme === "light"}
                      class:border-gray-700={currentTheme === "dark"}
                    >
                      {#if fileResponse.ok.contentType.startsWith("image/")}
                        <img
                          src={generateImageSrc(fileResponse.ok.filedata)}
                          alt={fileResponse.ok.fileName}
                          class="w-12 h-12 object-cover rounded"
                        />
                      {:else}
                        <div
                          class="w-12 h-12 flex items-center justify-center rounded"
                          class:bg-gray-100={currentTheme === "light"}
                          class:bg-gray-800={currentTheme === "dark"}
                        >
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            class="h-6 w-6"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                            class:text-gray-500={currentTheme === "light"}
                            class:text-gray-400={currentTheme === "dark"}
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              stroke-width="2"
                              d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                            />
                          </svg>
                        </div>
                      {/if}

                      <div class="flex-1 min-w-0">
                        <p
                          class="text-sm truncate"
                          class:text-gray-800={currentTheme === "light"}
                          class:text-gray-200={currentTheme === "dark"}
                        >
                          {fileResponse.ok.fileName}
                        </p>
                        <p
                          class="text-xs"
                          class:text-gray-500={currentTheme === "light"}
                          class:text-gray-400={currentTheme === "dark"}
                        >
                          {formatFileSize(fileResponse.ok.size)}
                        </p>
                      </div>

                      <a
                        href={generateImageSrc(fileResponse.ok.filedata)}
                        download={fileResponse.ok.fileName}
                        class="p-2 rounded-full hover:bg-opacity-20 transition-colors"
                        class:hover:bg-blue-500={currentTheme === "light"}
                        class:hover:bg-blue-600={currentTheme === "dark"}
                        title="Download"
                      >
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-5 w-5"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                          class:text-gray-600={currentTheme === "light"}
                          class:text-gray-400={currentTheme === "dark"}
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"
                          />
                        </svg>
                      </a>
                    </div>
                  {/if}
                {:catch error}
                  <div
                    class="text-sm p-2 rounded"
                    class:bg-red-100={currentTheme === "light"}
                    class:bg-red-900={currentTheme === "dark"}
                    class:text-red-700={currentTheme === "light"}
                    class:text-red-300={currentTheme === "dark"}
                  >
                    Failed to load attachment
                  </div>
                {/await}
              {/if}
            {/each}
          </div>
        </div>
      {/if}


      {#if pageType!=="draft" && pageType!=="trash"}
      <div
        class="mt-4 pt-4 border-t flex justify-end"
        class:border-gray-200={currentTheme === "light"}
        class:border-gray-700={currentTheme === "dark"}
      >
        <button
          on:click|stopPropagation={handleReply}
          class="px-4 py-2 rounded-full font-medium transition-all duration-200 flex items-center gap-2 hover:gap-3 text-white"
          class:bg-blue-600={currentTheme === "light"}
          class:bg-blue-500={currentTheme === "dark"}
          class:hover:bg-blue-700={currentTheme === "light"}
          class:hover:bg-blue-600={currentTheme === "dark"}
        >
          Reply
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-4 w-4"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M14 5l7 7m0 0l-7 7m7-7H3"
            />
          </svg>
        </button>
      </div>
      {/if}
    </div>
  {/if}
</div>

{#if showReplyModal && message}
<div class="fixed inset-0 z-[100] overflow-y-auto">
  <div class="fixed inset-0 bg-gray-900/30 backdrop-blur-[2px]"
       on:click={() => (showReplyModal = false)}
       transition:fade>
  </div>

  <div class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
    <div class="relative inline-block align-bottom rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg w-full"
         transition:fade>
      <WriteMail
        to={message.from}
        parentMailId={message.parentMailId || message.id}
        isReply={true}
        on:close={() => (showReplyModal = false)}
        on:send={handleSendReply}
      />
    </div>
  </div>
</div>
{/if}

{#if showEditModal && message}
<div class="fixed inset-0 z-[100] overflow-y-auto">
  <div class="fixed inset-0 bg-gray-900/30 backdrop-blur-[2px]"
       on:click={() => (showEditModal = false)}
       transition:fade>
  </div>

  <div class="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
    <div class="relative inline-block align-bottom rounded-lg text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg w-full"
         transition:fade>
      <WriteMail
        to={message.to}
        subject={message.subject}
        message={message.body}
        parentMailId={message.parentMailId}
        originalMessageId={message.id}
        isEdit={true}
        on:close={() => (showEditModal = false)}
        on:send={handleEditComplete}
      />
    </div>
  </div>
</div>
{/if}

{#if showDeleteConfirmation}
<div class="absolute top-0 right-0 z-50 mt-8 mr-2"
           on:click|stopPropagation>
        <ConfirmationDialogue
          title="Delete Mail"
          message="Are you sure you want to delete this mail?"
          confirmText="Delete"
          on:confirm={handleDeleteConfirm}
          on:cancel={() => {
            showDeleteConfirmation = false;
          }}
        />
      </div>
{/if}
