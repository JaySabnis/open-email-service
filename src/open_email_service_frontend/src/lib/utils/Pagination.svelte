<script>
  import { theme } from "$lib/store/theme";
  import { get } from 'svelte/store';
  
  let currentTheme = get(theme);
  
  export let currentPage = 1;
  export let hasNextPage = false;
  export let onPageChange;

  function changePage(newPage) {
    if (newPage < 1) return;
    onPageChange?.(newPage);
  }

  theme.subscribe((value) => {
    currentTheme = value;
  });
</script>

<div class="flex justify-center items-center gap-3 my-6">
  <button 
    class="px-4 py-2 rounded-lg border text-sm font-medium transition disabled:opacity-50 disabled:cursor-not-allowed"
    class:border-gray-300={currentTheme === 'light'}
    class:border-gray-600={currentTheme === 'dark'}
    class:text-gray-700={currentTheme === 'light'}
    class:text-gray-200={currentTheme === 'dark'}
    class:bg-white={currentTheme === 'light'}
    class:bg-gray-800={currentTheme === 'dark'}
    class:hover:bg-gray-100={currentTheme === 'light'}
    class:hover:bg-gray-700={currentTheme === 'dark'}
    on:click={() => changePage(currentPage - 1)}
    disabled={currentPage === 1}
  >
    ← Prev
  </button>

  <span class="text-sm font-semibold"
        class:text-gray-700={currentTheme === 'light'}
        class:text-gray-200={currentTheme === 'dark'}>
    Page {currentPage}
  </span>

  <button 
    class="px-4 py-2 rounded-lg border text-sm font-medium transition disabled:opacity-50 disabled:cursor-not-allowed"
    class:border-gray-300={currentTheme === 'light'}
    class:border-gray-600={currentTheme === 'dark'}
    class:text-gray-700={currentTheme === 'light'}
    class:text-gray-200={currentTheme === 'dark'}
    class:bg-white={currentTheme === 'light'}
    class:bg-gray-800={currentTheme === 'dark'}
    class:hover:bg-gray-100={currentTheme === 'light'}
    class:hover:bg-gray-700={currentTheme === 'dark'}
    on:click={() => changePage(currentPage + 1)}
    disabled={!hasNextPage}
  >
    Next →
  </button>
</div>
