<script>
  export let currentPage = 1;
  export let hasNextPage = false;
  export let onPageChange;

  function changePage(newPage) {
    if (newPage < 1) return;
    onPageChange?.(newPage);
  }
</script>

<div class="flex justify-center items-center gap-3 my-6">
  <button 
    class="px-4 py-2 rounded-lg border border-gray-300 text-sm font-medium text-gray-700 bg-white hover:bg-gray-100 transition disabled:opacity-50 disabled:cursor-not-allowed"
    on:click={() => changePage(currentPage - 1)}
    disabled={currentPage === 1}
  >
    ← Prev
  </button>

  <span class="text-sm font-semibold text-gray-700">
    Page {currentPage}
  </span>

  <button 
    class="px-4 py-2 rounded-lg border border-gray-300 text-sm font-medium text-gray-700 bg-white hover:bg-gray-100 transition disabled:opacity-50 disabled:cursor-not-allowed"
    on:click={() => changePage(currentPage + 1)}
    disabled={!hasNextPage}
  >
    Next →
  </button>
</div>
