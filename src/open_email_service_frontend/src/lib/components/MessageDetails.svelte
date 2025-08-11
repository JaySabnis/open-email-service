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
  // import { faTrashAlt } from '@fortawesome/free-solid-svg-icons';
  // import { FontAwesomeIcon } from '@fortawesome/svelte-fontawesome'
  // import { faRotateLeft } from '@fortawesome/free-solid-svg-icons';
  // import ConfirmationDialogue from './ConfirmationDialogue.svelte';
  import ThreadMessage from './ThreadMessage.svelte';
  export let message;

  const dispatch = createEventDispatcher();
  let mailData;
  let error = null;
  let showReplyModal = false; 
  let fromUser = null;
  let currentTheme = get(theme);
  let showDeleteConfirmation = false;
  export let pageType = "inbox";
  let threadMessages = [];

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
      showLoader('Loading mail...');
      error = null;
      const mail = await mailsStore.getMailById(message.id);
      
      if (mail) {
        message = mail;
        // console.log("Message data:", message?.ok);
        
        threadMessages = message?.ok?.slice().sort((a, b) => {
          return Number(a.createdOn) - Number(b.createdOn);
        }) || [];
        
        if (threadMessages.length > 1) {
          const parentId = threadMessages[0].id;
          threadMessages = threadMessages.map((msg, index) => ({
            ...msg,
            parentMailId: index === 0 ? null : parentId
          }));
        }

        for (const msg of threadMessages) {
          if (msg.attachments && msg.attachments.length > 0) {
            const attachmentId = msg.attachments[0][0]?.fileId;
            if (attachmentId) {
              try {
                const fileResponse = await mailsStore.getFileById(attachmentId);
                const fileData = fileResponse?.ok;
                
                if (fileData) {
                  msg.attachmentData = fileData;
                  
                  if (fileData.contentType.startsWith('image/')) {
                    msg.attachmentSrc = generateImageSrc(fileData.filedata);
                  } else {
                    const blob = new Blob([fileData.filedata], { type: fileData.contentType });
                    msg.downloadUrl = URL.createObjectURL(blob);
                  }
                }
              } catch (err) {
                console.error(`Error fetching attachment ${attachmentId}:`, err);
                msg.attachmentError = err;
              }
            }
          }
        }
        
        const firstMessage = threadMessages[0];
        if (firstMessage) {
          const fromUserResponse = await profileStore.getProfileByUserAddress(firstMessage.from);
          fromUser = fromUserResponse?.ok || null;

          if (!fromUser) {
            try {
              const currentUserResponse = await profileStore.getProfile();
              fromUser = currentUserResponse?.ok || null;
            } catch (err) {
              console.error('Error fetching current user profile:', err);
            }
          }
        }
        // console.log("Thread messages:", threadMessages);
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

  function handleRefresh() {
    getMail();
  }

  // async function handleDelete(messageId) {
  //   if (!messageId) return;
    
  //   try {
  //     showLoader('Deleting message...');
  //     await mailsStore.deleteEmail(messageId);
  //     window.location.reload();
  //   } catch (err) {
  //     console.error("Failed to delete message:", err);
  //     error = err;
  //   } finally {
  //     hideLoader();
  //   }
  // }

  // async function handleRestore(messageId) {
  //   if (!messageId) return;
    
  //   try {
  //     showLoader('Restoring Mail...');
  //     await mailsStore.restoreEmail(messageId);
  //     window.location.reload();
  //   } catch (err) {
  //     console.error("Failed to restore mail:", err);
  //     error = err;
  //   } finally {
  //     hideLoader();
  //   }
  // }

  // async function markAsImportant(msgId) { 
  //   try {
  //     showLoader('Marking important...'); 
  //     const msg = await mailsStore.markItAsImportant(msgId);
  //     // window.location.reload();
  //   } catch (err) {
  //     console.error("Failed to mark as important", error);
  //     error = err;
  //   } finally {
  //     hideLoader();
  //   }
  // }

  //  async function markAsNotImportant(msgId) { 
  //   try {
  //     showLoader('Marking as Unimportant...'); 
  //     const msg = await mailsStore.markAsNotImportant(msgId);
  //     // window.location.reload();
  //   } catch (err) {
  //     console.error("Failed to mark as unimportant", error);
  //     error = err;
  //   } finally {
  //     hideLoader();
  //   }
  // }
  
  // function handleDeleteClick() {
  //   showDeleteConfirmation = true;
  // }
  
  // function handleDeleteConfirm() {
  //   showDeleteConfirmation = false;
  //   handleDelete(mailData?.id);
  // }

  let lastMessageId = null;

  $: if (message?.id && message.id !== lastMessageId) {
    // console.log("Fetching mail for message ID:", message.id);
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
      <h2 class="text-2xl font-semibold"
          class:text-gray-800={currentTheme === 'light'}
          class:text-gray-200={currentTheme === 'dark'}>
        {threadMessages[0]?.subject || ''}
      </h2>
      <div class="flex gap-2">
        <!-- {#if pageType !== 'trash'}
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
        {/if} -->

        <!-- {#if pageType === 'trash'}
          <button
            on:click={() => handleRestore(threadMessages[0]?.id)}
            title="Restore Mail"
            class="flex items-center gap-1 text-xs text-green-600 hover:text-green-800 transition-colors px-1 py-0 rounded border border-green-300"
          >
            <FontAwesomeIcon icon={faRotateLeft} class="h-2 w-2" />
            <span>Restore</span>
          </button>
        {/if} -->

        <!-- {#if showDeleteConfirmation}
          <ConfirmationDialogue
            title="Delete Message"
            message="Are you sure you want to delete this message? This action cannot be undone."
            confirmText="Delete"
            on:confirm={handleDeleteConfirm}
            on:cancel={() => showDeleteConfirmation = false}
          />
        {/if} -->
        <button
          on:click={close}
          class="transition text-lg p-2 rounded-full"
          class:text-gray-500={currentTheme === 'light'}
          class:text-gray-400={currentTheme === 'dark'}
          class:hover:bg-gray-100={currentTheme === 'light'}
          class:hover:bg-gray-800={currentTheme === 'dark'}
          class:hover:text-red-600={currentTheme === 'light'}
          class:hover:text-red-500={currentTheme === 'dark'}
          aria-label="Close mail details"
          title="Close"
        >
          ✖
        </button>
      </div>
    </div>

    <div class="space-y-3">
      {#each threadMessages as message, index}
        <ThreadMessage 
          {message} 
          isFirst={index === 0}
          {pageType}
          on:refresh={handleRefresh}
          close={close}
        />
      {/each}
    </div>

    {#if showReplyModal && threadMessages[0]}
      <div class="fixed inset-0 flex items-center justify-center p-4 z-50"
           class:bg-gray-900={currentTheme === 'light'}
           class:bg-gray-950={currentTheme === 'dark'}>
        <WriteMail 
          to={threadMessages[0].from}
          parentMailId={threadMessages[0].id}
          isReply={true} 
          on:close={() => showReplyModal = false}
          on:send={handleSendReply}
        />
      </div>
    {/if}
  {/if}
</div>