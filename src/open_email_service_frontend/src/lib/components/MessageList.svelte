<script>
  import { createEventDispatcher } from "svelte";
  import { onMount } from "svelte";
  import { mailsStore } from "$lib/store/mails-store";
  import Loader from "$lib/components/Loader.svelte";
  import { get } from "svelte/store";
  import Pagination from "$lib/utils/Pagination.svelte";
  // import { pageLoading } from '$lib/store/loading';
  import { page } from '$app/stores';

  const dispatch = createEventDispatcher();

  let searchTerm = "";
  let mails = [];
  let loading = false;
  let pageNumber = 1;
  let pageSize = 10;
  let totalInboxMails = 0;
  let hasNextPage = false;
  let currentTheme;
  let currentColors;
  let isSentPage = false;

  function selectMessage(msg) {
    console.log("Selected message:", msg);
    dispatch("select", msg);
  }

  async function getMails() {
    loading = true;
    const pageNumberOpt = [pageNumber];
    const pageSizeOpt = [pageSize];

    try {
      let mailData;
      if (isSentPage) {
        mailData = await mailsStore.fetchOutboxMails(pageNumberOpt, pageSizeOpt);
      } else {
        mailData = await mailsStore.fetchInboxMails(pageNumberOpt, pageSizeOpt);
      }

      mails = mailData.data;
      hasNextPage = Number(mailData.totalPages) > pageNumber;
      console.log("Fetched mails:", mails);
      loading = false;
      // pageLoading.set(false);
    } catch (error) {
      console.error("Failed to fetch mails:", error);
      mails = [];
    } finally {
      loading = false;
      // pageLoading.set(false);
    }
  }

  function handlePageChange(newPage) {
    pageNumber = newPage;
    getMails();
  }

  onMount(async () => {
    isSentPage = $page.url.pathname.includes('/sent');
    console.log("Mounting MessageList component for", isSentPage ? "sent" : "inbox");
    await getMails();
    return () => unsubscribeTheme();
  });

  $: {
    isSentPage = $page.url.pathname.includes('/sent');
    if (initialized) {
      getMails();
    }
  }
  
  let initialized = false;
  $: if (mails.length) initialized = true;
</script>

<div class="space-y-4 p-6 overflow-y-auto h-screen">
  <h2 class="text-xl font-bold mb-4">
    {isSentPage ? "Sent Messages" : "Inbox Messages"}
  </h2>
  
  <input
    type="text"
    placeholder="Search by subject..."
    bind:value={searchTerm}
    class="w-full mb-4 p-2 border rounded"
  />
  
  {#if loading}
    <div class="flex justify-center items-center h-64">
      <Loader />
    </div>
  {:else if mails && Array.isArray(mails) && mails.length}
    <div class="w-full p-1">
      {#each mails as msg, i}
        <div
          class="transition-all duration-200 border shadow-sm px-4 py-3 cursor-pointer flex justify-between items-start hover:opacity-95"
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
            {new Date(Number(msg.createdOn) / 1_000_000).toLocaleString()}
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
