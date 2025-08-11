<script>
  import { loaderStore } from "$lib/store/loader-store";
  import { theme } from "$lib/store/theme";
  import { get } from 'svelte/store';
  
  let currentTheme = get(theme);
  
  theme.subscribe((value) => {
    currentTheme = value;
  });
</script>

{#if $loaderStore.isLoading}
  <div class="fixed inset-0 z-100 flex items-center justify-center">
    <div class="absolute inset-0 opacity-50"
         class:bg-gray-900={currentTheme === 'dark'}
         class:bg-gray-700={currentTheme === 'light'}></div>
    
    <div class="relative z-10 p-6 rounded-lg shadow-xl w-full max-w-xs"
         class:bg-gray-800={currentTheme === 'dark'}
         class:bg-white={currentTheme === 'light'}>
      <div class="flex flex-col items-center space-y-4">
        <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2"
             class:border-blue-400={currentTheme === 'dark'}
             class:border-blue-500={currentTheme === 'light'}></div>
      
        <p class:text-gray-200={currentTheme === 'dark'}
           class:text-gray-800={currentTheme === 'light'}
           class="text-center">
          {$loaderStore.message}
        </p>
      </div>
    </div>
  </div>
{/if}