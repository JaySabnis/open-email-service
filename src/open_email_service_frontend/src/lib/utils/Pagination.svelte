<script>
  export let currentPage = 1;
  export let hasNextPage = false;
  export let onPageChange;

  function changePage(newPage) {
    if (newPage < 1) return;
    onPageChange?.(newPage);
  }
</script>

<div class="flex justify-center items-center gap-2 my-4">
  <button 
    class="px-3 py-1 rounded border text-sm"
    on:click={() => changePage(currentPage - 1)}
    disabled={currentPage === 1}
  >
    Prev
  </button>

  <span class="text-sm">Page {currentPage}</span>

  <button 
    class="px-3 py-1 rounded border text-sm"
    on:click={() => changePage(currentPage + 1)}
    disabled={!hasNextPage}
  >
    Next
  </button>
</div>
