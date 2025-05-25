<script>
  import { onMount } from "svelte";
  import { mailsStore } from "$lib/store/mails-store";
  import Loader from "$lib/components/loader.svelte";
  import { theme } from "$lib/store/theme";
  import { colors } from "$lib/store/colors";
  import { get } from "svelte/store";
  import { goto } from '$app/navigation';
  import Pagination from "$lib/utils/Pagination.svelte";

  let mails;
  let loading = false;
  let pageNumber = 1;
  let pageSize = 10;
  let totalInboxMails = 0;
  let hasNextPage = false;

  function opt(value) {
    if (value === undefined || value === null || value === '') {
      return [];  
    }
    return [value]; 
  }

 async function getInboxMails() {
    loading = true;

    const pageNumberOpt = [pageNumber];
    const pageSizeOpt = [pageSize];

    // const inboxData = await mailsStore.fetchInboxMails(pageNumberOpt, pageSizeOpt);
    const outboxData = await mailsStore.fetchOutboxMails(pageNumberOpt, pageSizeOpt);

    mails = outboxData;
    hasNextPage = outboxData.length === pageSize;

    console.log(mails, outboxData, "mails");
    loading = false;
  }

  function handlePageChange(newPage) {
    pageNumber = newPage;
    getInboxMails();
  }
  onMount(async () => {
    await getInboxMails();
  });

  let currentTheme;
  let currentColors;

  const unsubscribeTheme = theme.subscribe(value => {
    currentTheme = value;
    const colorsValue = get(colors);
    currentColors = colorsValue[currentTheme];
  });
</script>

{#if loading}
  <Loader message="Fetching your emails..." />
{:else if mails && Array.isArray(mails) && mails.length}
  <div class="w-full p-1">
    {#each mails as msg, i}
      <div
        class="transition-all duration-200 border shadow-sm px-4 py-3 cursor-pointer flex justify-between items-start hover:opacity-95"
        style="
          background-color: {currentColors.surface};
          color: {currentColors.color};
          border-color: {currentColors.borderColor};
        "
        on:mouseenter={() => (event.currentTarget.style.boxShadow = `0 0 1px 1px ${currentColors.inputFocus}`)}
        on:mouseleave={() => (event.currentTarget.style.boxShadow = 'none')}
        on:click={() => goto(`/sent/${msg.id}`)}
      >
        <div class="flex-1">
          <p class="font-semibold text-base truncate" style="color: {currentColors.headingColor}">
            {msg?.from || `Sender ${i + 1}`}
          </p>
          <p class="text-sm truncate" style="color: {currentColors.colorMuted}">
            {msg?.subject || 'No Subject'}
          </p>
        </div>
        <span class="text-xs whitespace-nowrap pl-4" style="color: {currentColors.colorMuted}">
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
