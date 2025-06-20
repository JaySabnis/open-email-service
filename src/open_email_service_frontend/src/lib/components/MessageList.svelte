<script>
  import { createEventDispatcher } from "svelte";
  import { onMount } from "svelte";
  import { mailsStore } from "$lib/store/mails-store";
  import { showLoader, hideLoader } from '$lib/store/loader-store'; 
  import { get } from "svelte/store";
  import Pagination from "$lib/utils/Pagination.svelte";
  import { page } from '$app/stores';
  import { authStore } from '$lib/store/auth-store'; 

  const dispatch = createEventDispatcher();
  export let selectedMessage;
  let searchTerm = "";
  let mails = [];
  let pageNumber = 1;
  let pageSize = 10;
  let totalInboxMails = 0;
  let hasNextPage = false;
  let currentTheme;
  let currentColors;
  let isSentPage = false;
  let error = null;

 function selectMessage(msg) {
    if (!selectedMessage || msg?.id.toString() !== selectedMessage?.id.toString()) {
      dispatch('select', msg);
    }
  }

  async function getMails() {
    try {
      showLoader('Loading messages...'); 
      
      const identity = await authStore.sync();
      if (!identity?.getPrincipal) {
        throw new Error("Not authenticated");
      }

      const pageNumberOpt = [pageNumber];
      const pageSizeOpt = [pageSize];

      let mailData;
      if (isSentPage) {
        mailData = await mailsStore.fetchOutboxMails(pageNumberOpt, pageSizeOpt);
      } else {
        mailData = await mailsStore.fetchInboxMails(pageNumberOpt, pageSizeOpt);
      }

      mails = mailData?.data || [];
      hasNextPage = Number(mailData?.totalPages) > pageNumber;
    } catch (err) {
      console.error("Failed to fetch mails:", err);
      error = err;
      mails = [];
    } finally {
      hideLoader(); 
    }
  }

  function handlePageChange(newPage) {
    pageNumber = newPage;
    getMails();
  }

  onMount(async () => {
    isSentPage = $page.url.pathname.includes('/sent');
    await getMails();
  });

  $: {
    const newIsSentPage = $page.url.pathname.includes('/sent');
    if (newIsSentPage !== isSentPage) {
      isSentPage = newIsSentPage;
      getMails();
    }
  }
</script>

<div class="space-y-4 p-6 overflow-y-auto h-screen bg-white">
  <h2 class="text-xl font-bold mb-4">
    {isSentPage ? "Sent Mails" : "Inbox Mails"}
  </h2>
  
  <input
    type="text"
    placeholder="Search by subject..."
    bind:value={searchTerm}
    class="w-full mb-4 p-2 border rounded"
  />
  
  {#if error}
    <div class="text-red-500 text-center p-4">
      Error loading messages: {error.message}
    </div>
  {:else if mails.length > 0}
    <div class="w-full p-1">
      {#each mails as msg, i}
        <div
          class="transition-all duration-200 border shadow-sm px-4 py-3 cursor-pointer flex justify-between items-start hover:opacity-95"
          class:bg-blue-50={selectedMessage?.id === msg.id}
          on:click={() => selectMessage(msg)}
        >
          <div class="flex-1">
            <p class="font-semibold text-base truncate">
              {isSentPage ? (msg?.to || `Recipient ${i + 1}`) : (msg?.from || `Sender ${i + 1}`)}
            </p>
            <p class="text-sm truncate">
              {msg?.subject || 'No Subject'}
            </p>
          </div>
          <span class="text-xs whitespace-nowrap pl-4">
            {new Date(Number(msg?.createdOn) / 1_000_000).toLocaleString()}
          </span>
        </div>
      {/each}
      
      <Pagination
        currentPage={pageNumber}
        {hasNextPage}
        onPageChange={handlePageChange}
      />
    </div>
  {:else}
    <p class="text-gray-500 text-center">No messages to show.</p>
  {/if}
</div>