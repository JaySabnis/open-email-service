<script>
  import { createEventDispatcher } from 'svelte';
  import { theme } from "$lib/store/theme";
  import { get } from 'svelte/store';
  
  export let title = "Confirm Action";
  export let message = "Are you sure you want to perform this action?";
  export let confirmText = "Confirm";
  export let cancelText = "Cancel";
  
  let currentTheme = get(theme);
  
  theme.subscribe((value) => {
    currentTheme = value;
  });
  
  const dispatch = createEventDispatcher();
</script>

<div class="fixed inset-0 z-50 flex items-center justify-center">
  <div class="absolute inset-0 opacity-50"
       class:bg-gray-900={currentTheme === 'dark'}
       class:bg-gray-700={currentTheme === 'light'}></div>
  
  <div class="relative z-10 p-6 rounded-lg shadow-xl w-full max-w-md"
       class:bg-gray-800={currentTheme === 'dark'}
       class:bg-white={currentTheme === 'light'}>
    
    <h3 class="text-lg font-medium mb-4"
        class:text-gray-100={currentTheme === 'dark'}
        class:text-gray-900={currentTheme === 'light'}>
      {title}
    </h3>
    
    <p class="mb-6"
       class:text-gray-300={currentTheme === 'dark'}
       class:text-gray-600={currentTheme === 'light'}>
      {message}
    </p>
    
    <div class="flex justify-end gap-3">
      <button
        on:click={() => dispatch('cancel')}
        class="px-4 py-2 rounded-md transition"
        class:text-gray-300={currentTheme === 'dark'}
        class:text-gray-700={currentTheme === 'light'}
        class:hover:bg-gray-700={currentTheme === 'dark'}
        class:hover:bg-gray-100={currentTheme === 'light'}>
        {cancelText}
      </button>
      
      <button
        on:click={() => dispatch('confirm')}
        class="px-4 py-2 rounded-md text-white transition"
        class:bg-red-500={currentTheme === 'dark'}
        class:bg-red-600={currentTheme === 'light'}
        class:hover:bg-red-600={currentTheme === 'dark'}
        class:hover:bg-red-700={currentTheme === 'light'}>
        {confirmText}
      </button>
    </div>
  </div>
</div>