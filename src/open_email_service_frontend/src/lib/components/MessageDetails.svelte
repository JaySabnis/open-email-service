<script>
  import { mailsStore } from '$lib/store/mails-store';
  import { createEventDispatcher } from 'svelte';
  import { onMount } from 'svelte';
  import { showLoader, hideLoader } from '$lib/store/loader-store';
  import WriteMail from './WriteMail.svelte'; 
  import {profileStore} from '$lib/store/profile-store'
  import { generateImageSrc } from '$lib/utils/helpers';
  import { theme } from "$lib/store/theme";
  import { get } from 'svelte/store';
  import { faTrashAlt } from '@fortawesome/free-solid-svg-icons';
  import { FontAwesomeIcon } from '@fortawesome/svelte-fontawesome'
  import { faRotateLeft } from '@fortawesome/free-solid-svg-icons';
  import ConfirmationDialogue from './ConfirmationDialogue.svelte';
  export let message;

  const dispatch = createEventDispatcher();
  let mailData;
  let error = null;
  let showReplyModal = false; 
  let fromUser = null;
  let currentTheme = get(theme);
  let showDeleteConfirmation = false;
  export let pageType = "inbox";

  function close() {
    dispatch('close');
  }

  function handleReply() {
    showReplyModal = true;
  }

  function handleSendReply(event) {
    // console.log('Replying with:', event.detail);
    showReplyModal = false;
  }

  async function getMail() {
    try {
      showLoader('Loading message...');
      error = null;
      const mail = await mailsStore.getMailById(message.id);
      
      if (mail) {
        message = mail;
        mailData = mail?.ok?.[0];
        const fromUserResponse = await profileStore.getProfileByUserAddress(mailData.from);
        fromUser = fromUserResponse?.ok || null;

        if (!fromUser) {
        try {
          const currentUserResponse = await profileStore.getProfile();
          fromUser = currentUserResponse?.ok || null;
        } catch (err) {
          console.error('Error fetching current user profile:', err);
        }
      }

        // console.log(fromUser,"fromuser data")
      } else {
        throw new Error('Mail not found');
      }
    } catch (err) {
      error = err;
      console.error('Error fetching mail:', err);
    } finally {
      hideLoader();
    }
  }

  async function handleDelete(messageId) {
    if (!messageId) return;
    
    try {
      showLoader('Deleting message...');
      await mailsStore.deleteEmail(messageId);
      window.location.reload();
    } catch (err) {
      console.error("Failed to delete message:", err);
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
      window.location.reload();
    } catch (err) {
      console.error("Failed to restore mail:", err);
      error = err;
    } finally {
      hideLoader();
    }
  }

  async function markAsImportant(msgId) { 
    try {
      showLoader('Marking important...'); 
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
      showLoader('Marking as Unimportant...'); 
      const msg = await mailsStore.markAsNotImportant(msgId);
      // window.location.reload();
    } catch (err) {
      console.error("Failed to mark as unimportant", error);
      error = err;
    } finally {
      hideLoader();
    }
  }
  
  function handleDeleteClick() {
    showDeleteConfirmation = true;
  }
  
  function handleDeleteConfirm() {
    showDeleteConfirmation = false;
    handleDelete(mailData?.id);
  }

  let lastMessageId = null;

  $: if (message?.id && message.id !== lastMessageId) {
    lastMessageId = message.id;
    getMail();
  }

   theme.subscribe((value) => {
    currentTheme = value;
  });
</script>

<div 
  class="p-6 h-screen overflow-y-auto flex flex-col"
  class:bg-white={currentTheme === 'light'}
  class:bg-gray-900={currentTheme === 'dark'}
>
  {#if error}
    <div class="flex-grow flex items-center justify-center text-red-500 text-lg font-medium">
      Failed to load message: {error.message}
    </div>
  {:else}
    <div class="flex justify-between items-start mb-4">
  <h2 class="text-2xl font-semibold ml-[3.5rem]"
      class:text-gray-800={currentTheme === 'light'}
      class:text-gray-200={currentTheme === 'dark'}>
    {mailData?.subject || 'No Subject'}
  </h2>
  <div class="flex gap-2">
   {#if pageType !== 'trash'}
    <button
      on:click={handleDeleteClick}
      class="transition text-lg p-2 rounded-full"
      class:text-gray-500={currentTheme === 'light'}
      class:text-gray-400={currentTheme === 'dark'}
      class:hover:bg-red-100={currentTheme === 'light'}
      class:hover:bg-red-900={currentTheme === 'dark'}
      class:hover:text-red-600={currentTheme === 'light'}
      class:hover:text-red-400={currentTheme === 'dark'}
      aria-label="Delete message"
      title="Delete"
    >
      <FontAwesomeIcon icon={faTrashAlt} class="h-4 w-4" />
    </button>
  {/if}

    {#if pageType === 'trash'}
  <button
    on:click={() => handleRestore(mailData.id)}
    title="Restore Mail"
    class="flex items-center gap-1 text-xs text-green-600 hover:text-green-800 transition-colors px-1 py-0 rounded border border-green-300"
  >
    <FontAwesomeIcon icon={faRotateLeft} class="h-2 w-2" />
    <span>Restore</span>
  </button>
{/if}


    {#if showDeleteConfirmation}
      <ConfirmationDialogue
        title="Delete Message"
        message="Are you sure you want to delete this message? This action cannot be undone."
        confirmText="Delete"
        on:confirm={handleDeleteConfirm}
        on:cancel={() => showDeleteConfirmation = false}
      />
    {/if}
    <button
      on:click={close}
      class="transition text-lg p-2 rounded-full"
      class:text-gray-500={currentTheme === 'light'}
      class:text-gray-400={currentTheme === 'dark'}
      class:hover:bg-gray-100={currentTheme === 'light'}
      class:hover:bg-gray-800={currentTheme === 'dark'}
      class:hover:text-red-600={currentTheme === 'light'}
      class:hover:text-red-500={currentTheme === 'dark'}
      aria-label="Close message details"
      title="Close"
    >
      ✖
    </button>
  </div>
</div>

    <div class="flex gap-4 mb-4">
      <div class="w-14 flex-shrink-0">
        {#if fromUser?.profileImage}
          <img 
            src={generateImageSrc(fromUser.profileImage)}
            alt="Profile Image"
            class="w-12 h-12 rounded-full object-cover border mt-1"
            class:border-gray-300={currentTheme === 'light'}
            class:border-gray-600={currentTheme === 'dark'}
          />
        {/if}
      </div>

      <div class="flex-1 flex justify-between">
        <div>
          <div class="flex items-center flex-wrap gap-2 mb-1">
            <p class="text-sm font-medium"
               class:text-gray-700={currentTheme === 'light'}
               class:text-gray-300={currentTheme === 'dark'}>
              {fromUser?.name || ''} {fromUser?.surname || ''}
            </p>
            <p class="text-xs lowercase"
               class:text-gray-500={currentTheme === 'light'}
               class:text-gray-400={currentTheme === 'dark'}>
              &lt;{mailData?.from || fromUser?.userAddress}&gt;
            </p>
          </div>
          <p class="text-xs mb-1"
             class:text-gray-500={currentTheme === 'light'}
             class:text-gray-400={currentTheme === 'dark'}>
            To: {mailData?.to || 'N/A'}
          </p>
        </div>
        <div class="flex items-center gap-3">
          <p class="text-xs whitespace-nowrap"
            class:text-gray-500={currentTheme === 'light'}
            class:text-gray-400={currentTheme === 'dark'}>
            {new Date(Number(mailData?.createdOn) / 1_000_000).toLocaleString()}
          </p>

          <div class="cursor-pointer text-yellow-500"
                  on:click|stopPropagation={pageType !== 'trash' && pageType !== 'draft'
                    ? () => mailData?.starred ? markAsNotImportant(mailData?.id) : markAsImportant(mailData?.id)
                    : null}
                >
                  {#if mailData?.starred}
                    ★
                  {:else}
                    ☆
                  {/if}
                </div>
        </div>
      </div>
    </div>

    <div class="flex-1 rounded-lg p-6 text-sm shadow-sm whitespace-pre-line ml-[3.5rem]"
         class:bg-white={currentTheme === 'light'}
         class:bg-gray-800={currentTheme === 'dark'}
         class:text-gray-800={currentTheme === 'light'}
         class:text-gray-200={currentTheme === 'dark'}>
      {#if mailData?.body}
        {mailData.body}
      {:else}
        <p class="italic"
           class:text-gray-400={currentTheme === 'light'}
           class:text-gray-500={currentTheme === 'dark'}>
          No mail content
        </p>
      {/if}
    </div>

    <div class="mt-4 flex justify-end ml-[3.5rem]">
      <button
        on:click={handleReply}
        class="px-5 py-2 rounded-full font-medium transition text-white shadow-md flex items-center gap-2"
        class:bg-blue-600={currentTheme === 'light'}
        class:bg-blue-500={currentTheme === 'dark'}
        class:hover:bg-blue-700={currentTheme === 'light'}
        class:hover:bg-blue-600={currentTheme === 'dark'}
      >
        Reply →
      </button>
    </div>
    

    {#if showReplyModal && mailData}
      <div class="fixed inset-0 flex items-center justify-center p-4 z-50"
           class:bg-gray-900={currentTheme === 'light'}
           class:bg-gray-950={currentTheme === 'dark'}>
        <WriteMail 
          to={mailData.from} 
          subject={`Re: ${mailData.subject || ''}`} 
          message={`\n\n---------- Original Message ----------\nFrom: ${mailData.from || ''}\nDate: ${new Date(Number(mailData.createdOn) / 1_000_000).toLocaleString()}\n\n${mailData.body || ''}`}
          on:close={() => showReplyModal = false}
          on:send={handleSendReply}
        />
      </div>
    {/if}
  {/if}
</div>