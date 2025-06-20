<script>
  import { loaderStore } from "$lib/store/loader-store";
</script>

{#if $loaderStore.isLoading}
  <div class="fixed inset-0 z-50 flex items-center justify-center">
    <div class="absolute inset-0 bg-gray-900 opacity-50"></div>
    
    <div class="relative z-10 bg-white dark:bg-gray-800 p-6 rounded-lg shadow-xl">
      <div class="flex flex-col items-center space-y-4">
        <div class="animate-spin rounded-full h-12 w-12 border-t-2 border-b-2 border-blue-500"></div>
        <p class="text-gray-800 dark:text-gray-200">{$loaderStore.message}</p>
      </div>
    </div>
  </div>
{/if}