<script>
  import { createEventDispatcher } from "svelte";
  import { onMount } from "svelte";
  import { mailsStore } from "$lib/store/mails-store";
  import { showLoader, hideLoader } from '$lib/store/loader-store'; 
  import { get } from "svelte/store";
  import Pagination from "$lib/utils/Pagination.svelte";
  import { authStore } from '$lib/store/auth-store'; 
  import { theme } from "$lib/store/theme";
  import { generateImageSrc } from '$lib/utils/helpers';
  import {profileStore} from '$lib/store/profile-store'
  import ConfirmationDialogue from './ConfirmationDialogue.svelte';
  import { faTrashAlt,faRotateLeft } from '@fortawesome/free-solid-svg-icons';
  import { FontAwesomeIcon } from '@fortawesome/svelte-fontawesome'
  import { getMails } from '$lib/utils/CommonApi';
  const dispatch = createEventDispatcher();
  export let selectedMessage;
  export let pageType = "inbox";
  
  let searchTerm = "";
  let mails = [];
  let pageNumber = 1;
  let pageSize = 10;
  let totalInboxMails = 0;
  let hasNextPage = false;
  let currentColors;
  let error = null;
  let filteredMails = [];
  let currentTheme = get(theme);
  let showDeleteConfirmation = false;
  let unselectMessage = false;
  let messageToDelete = null;

    function selectMessage(msg) {
      if (unselectMessage) {
        unselectMessage = false;
        dispatch('select', msg);
      } else if (!selectedMessage || msg?.id.toString() !== selectedMessage?.id.toString()) {
        dispatch('select', msg);
      }
    }

  async function fetchMails() {
    try {
      showLoader('Loading Mails...');
      const result = await getMails(pageType, pageNumber, pageSize);
      mails = result.mails;
      // console.log("Fetched mails:", mails);
      hasNextPage = result.hasNextPage;
      error = result.error;
    } catch (err) {
      console.error("Error in component while fetching mails:", err);
      error = err;
      mails = [];
    } finally {
      hideLoader();
    }
  }

  function handlePageChange(newPage) {
    pageNumber = newPage;
    fetchMails();
  }

  async function markAsImportant(msgId) { 
    try {
      showLoader('Marking important...'); 
      const msg = await mailsStore.markItAsImportant(msgId);
      getMails();
    } catch (err) {
      console.error("Failed to mark as important", error);
      error = err;
    } finally {
      hideLoader();
    }
  }

   async function markAsNotImportant(msgId) { 
    try {
      showLoader('Marking as Unimportant...'); 
      const msg = await mailsStore.markAsNotImportant(msgId);
      getMails();
    } catch (err) {
      console.error("Failed to mark as unimportant", error);
      error = err;
    } finally {
      hideLoader();
    }
  }

  function getMailboxTitle() {
    switch (pageType) {
      case "sent":
        return "Sent Mails";
      case "draft":
        return "Draft Mails";
      case "trash":
        return "Trash Mails";
      case "starred":
        return "Starred Mails";
      default:
        return "Inbox Mails";
    }
  }

   function getParticipant(msg, index) {
    switch (pageType) {
      case "sent":
        return msg?.from || `Recipient ${index + 1}`;
      case "draft":
        return msg?.from ? `Draft to: ${msg.to}` : `Unsaved draft ${index + 1}`;
      case "trash":
        return msg?.from ? `From: ${msg.from}` : `Deleted mail ${index + 1}`;
      case "starred":
        return msg?.from || `Starred sender ${index + 1}`;
      default: // inbox
        return msg?.from || `Sender ${index + 1}`;
    }
  }


  function handleDeleteClick(msg) {
    messageToDelete = msg.id; 
    showDeleteConfirmation = true;
  }

  function handleDeleteConfirm() {
    showDeleteConfirmation = false;
    if (messageToDelete) {
      unselectMessage=true;
      handleDelete(messageToDelete);
      messageToDelete = null; 
    }
  }

  async function handleDelete(messageId) {
    if (!messageId) return;
    
    try {
      showLoader('Deleting mail...');
      await mailsStore.deleteEmail(messageId);
      await fetchMails();
      unselectMessage = false;
    } catch (err) {
      console.error("Failed to delete mail:", err);
      error = err;
    } finally {
      hideLoader();
    }
  }

  async function handleRestore(messageId) {
    if (!messageId) return;
    
    try {
      showLoader('Restoring Mail...');
      await mailsStore.restoreEmail(messageId);
      await fetchMails();
      unselectMessage = false;
    } catch (err) {
      console.error("Failed to restore mail:", err);
      error = err;
    } finally {
      hideLoader();
    }
  }

    onMount(async () => {
    await fetchMails();
  });

  $: filteredMails = searchTerm.trim()
    ? mails.filter(m => (m.subject || '').toLowerCase().includes(searchTerm.trim().toLowerCase()))
    : mails;

  $: if (searchTerm) {
    pageNumber = 1;
  }

  theme.subscribe((value) => {
    currentTheme = value;
  });

</script>

<div class="space-y-4 p-6 overflow-y-auto h-screen"
     class:bg-white={currentTheme === 'light'}
     class:bg-gray-900={currentTheme === 'dark'}>
  
  <h2 class="text-lg font-semibold mb-6"
      class:text-gray-800={currentTheme === 'light'}
      class:text-gray-200={currentTheme === 'dark'}>
   {getMailboxTitle()}
  </h2>

  <input
    type="text"
    placeholder="Search by subject..."
    bind:value={searchTerm}
    class="w-full mb-6 px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-400"
    class:bg-white={currentTheme === 'light'}
    class:bg-gray-700={currentTheme === 'dark'}
    class:text-gray-800={currentTheme === 'light'}
    class:text-gray-200={currentTheme === 'dark'}
    class:border-gray-300={currentTheme === 'light'}
    class:border-gray-600={currentTheme === 'dark'}
  />

  {#if error}
    <div class="text-red-500 text-center p-4">
      Error loading mails: {error.message}
    </div>
  {:else if filteredMails.length > 0}
    <div class="space-y-4">
{#each filteredMails as msg, i (msg.id)}
    <div
    class="border rounded-lg shadow-sm hover:shadow-md transition-all duration-200 cursor-pointer p-1.5 flex justify-between items-start group"
    class:border-gray-300={currentTheme === 'light'}
    class:border-gray-600={currentTheme === 'dark'}
    class:bg-white={currentTheme === 'light' && (selectedMessage?.id === msg.id || msg.readFlag)}
    class:bg-gray-100={currentTheme === 'light' && selectedMessage?.id !== msg.id && !msg.readFlag}
    class:bg-gray-800={currentTheme === 'dark' && (selectedMessage?.id === msg.id || msg.readFlag)}
    class:bg-gray-700={currentTheme === 'dark' && selectedMessage?.id !== msg.id && !msg.readFlag}
    class:bg-blue-50={currentTheme === 'light' && selectedMessage?.id === msg.id}
    class:bg-blue-900={currentTheme === 'dark' && selectedMessage?.id === msg.id}
    on:click={() => {
      if (!unselectMessage) {
        msg.readFlag = true;
        selectMessage(msg);
      }
    }}
>
    <div class="flex flex-1 min-w-0 gap-2">
      {#if msg.profile?.profileImage}
        <img 
          src={generateImageSrc(msg.profile.profileImage)}
          alt="Profile" 
          class="w-10 h-10 rounded-full object-cover flex-shrink-0 mt-0.5"
        />
      {:else}
        <div class="w-10 h-10 rounded-full bg-gray-300 flex-shrink-0 flex items-center justify-center mt-0.5">
          {msg.mailData?.from?.substring(0, 2).toUpperCase() || '?'}
        </div>
      {/if}

      <div class="flex-1 min-w-0">
        <div class="flex items-baseline gap-2">
          <p class="text-sm font-medium truncate group-hover:text-blue-600"
             class:text-gray-800={currentTheme === 'light'}
             class:text-gray-200={currentTheme === 'dark'}>
            {getParticipant(msg, i)}
          </p>
        </div>

        <p class="text-xs truncate"
           class:text-gray-600={currentTheme === 'light'}
           class:text-gray-400={currentTheme === 'dark'}>
          {msg?.subject || ''}
        </p>

        {#if msg?.preview}
          <p class="text-xs truncate text-gray-500 mt-0.5"
             class:text-gray-500={currentTheme === 'light'}
             class:text-gray-300={currentTheme === 'dark'}>
            {msg?.preview}
          </p>
        {/if}
      </div>
    </div>

    <div class="flex flex-col justify-between items-end h-full ml-4 gap-4">
  <div class="flex items-center gap-2">
    <div
      class="cursor-pointer text-yellow-500 text-sm flex items-center justify-center h-4 w-4"
      on:click|stopPropagation={pageType !== 'trash' && pageType !== 'draft'
        ? () => {
          // msg.starred = !msg.starred;
          msg?.starred ? markAsNotImportant(msg.id) : markAsImportant(msg.id)}
        : null}
    >
      {#if msg?.starred}
        ★
      {:else}
        ☆
      {/if}
    </div>

    {#if pageType !== 'trash'}
      <button
          on:click|stopPropagation={() => handleDeleteClick(msg)}
          class="h-4 w-4 flex items-center justify-center"
          class:text-gray-500={currentTheme === 'light'}
          class:text-gray-400={currentTheme === 'dark'}
          class:hover:text-red-500={currentTheme === 'light'}
          class:hover:text-red-400={currentTheme === 'dark'}
          title="Delete"
        >
          <FontAwesomeIcon icon={faTrashAlt} class="h-4 w-4" />
        </button>
    {:else}
      <button
        on:click|stopPropagation={(e) => {
          e.stopPropagation();
          handleRestore(msg.id);
        }}
        title="Restore Mail"
        class="h-4 w-4 flex items-center justify-center text-green-600 hover:text-green-800"
      >
        <FontAwesomeIcon icon={faRotateLeft} class="h-4 w-4" />
      </button>
    {/if}
  </div>

  <div class="flex items-center gap-1 text-xs whitespace-nowrap mt-auto"
       class:text-gray-500={currentTheme === 'light'}
       class:text-gray-400={currentTheme === 'dark'}>
    <span>
      {new Date(Number(msg?.createdOn) / 1_000_000).toLocaleDateString()}
    </span>
    <span class="opacity-70">•</span>
    <span>
      {new Date(Number(msg?.createdOn) / 1_000_000).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}
    </span>
  </div>

    {#if showDeleteConfirmation && messageToDelete === msg.id}
      <div class="absolute top-0 right-0 z-50 mt-8 mr-2"
           on:click|stopPropagation>
        <ConfirmationDialogue
          title="Delete Mail"
          message="Are you sure you want to delete this mail?"
          confirmText="Delete"
          on:confirm={handleDeleteConfirm}
          on:cancel={() => {
            showDeleteConfirmation = false;
            messageToDelete = null;
          }}
        />
      </div>
    {/if}
  </div>
  </div>
{/each}
      <Pagination
        currentPage={pageNumber}
        {hasNextPage}
        onPageChange={handlePageChange}
      />
    </div>
  {:else}
    <p class="text-center"
       class:text-gray-500={currentTheme === 'light'}
       class:text-gray-400={currentTheme === 'dark'}>
      No mails to show.
    </p>
  {/if}
</div>