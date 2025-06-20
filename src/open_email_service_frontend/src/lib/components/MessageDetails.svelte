<script>
  import { mailsStore } from '$lib/store/mails-store';
  import { createEventDispatcher } from 'svelte';
  import { onMount } from 'svelte';
  import { showLoader, hideLoader } from '$lib/store/loader-store';
  import WriteMail from './WriteMail.svelte'; 

  export let message;

  const dispatch = createEventDispatcher();
  let currentTheme;
  let currentColors;
  let mailData;
  let error = null;
  let showReplyModal = false; 

  function close() {
    dispatch('close');
  }

  function handleReply() {
    showReplyModal = true;
  }

  function handleSendReply(event) {
    console.log('Replying with:', event.detail);
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

  let lastMessageId = null;

  $: if (message?.id && message.id !== lastMessageId) {
    lastMessageId = message.id;
    getMail();
  }

</script>

<div 
  class="p-6 h-screen overflow-y-auto flex flex-col"
  style="background-color: {currentColors?.cardBg || '#fff'}; color: {currentColors?.color || '#000'}"
>
  {#if error}
    <div class="flex-grow flex items-center justify-center text-red-500">
      Failed to load message: {error.message}
    </div>
  {:else}
    <div class="flex justify-between items-center mb-4">
      <div>
        <h2 class="text-xl font-bold">
          {mailData?.subject || 'No Subject'}
        </h2>
        <p class="text-sm">
          From: {mailData?.from || 'Unknown Sender'}
        </p>
        <p class="text-xs">
          {new Date(Number(mailData?.createdOn) / 1_000_000).toLocaleString()}
        </p>
      </div>
      <button
        on:click={close}
        class="text-sm px-3 py-1 rounded hover:opacity-90 transition-opacity"
        aria-label="Close message details"
      >
        ✖ Close
      </button>
    </div>

    <div class="border-t pt-4 flex-grow">
      {#if mailData?.body}
        <div class="whitespace-pre-line">
          {mailData.body}
        </div>
      {:else}
        <p>No message content</p>
      {/if}
    </div>

    <div class="mt-4 border-t pt-4">
      <button
        on:click={handleReply}
        class="px-4 py-2 rounded-md transition"
        style="
          background-color: {currentColors?.btn || '#3b82f6'};
          color: {currentColors?.btnText || '#ffffff'};
        "
      >
        Reply
      </button>
    </div>

   {#if showReplyModal && mailData}
  <div class="fixed inset-0 bg-gray-900/70 backdrop-blur-sm flex items-center justify-center p-4 z-50">
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