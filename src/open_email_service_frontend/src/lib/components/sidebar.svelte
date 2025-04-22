<script>
  export let isSidebarOpen = false;
  export let toggleSidebar;
</script>

<div
  class={`transition-all duration-300 bg-gray-100 text-black fixed top-0 left-0 h-full z-20 ${isSidebarOpen ? 'w-64' : 'w-16'} overflow-hidden`}
>
  <div class="absolute top-4 left-4 flex items-center">
    <button
      class="text-black text-2xl cursor-pointer p-2 bg-gray-150 rounded-full hover:bg-gray-200"
      on:click={toggleSidebar}
    >
      {#if isSidebarOpen}
        <span>&#8592;</span> 
      {:else}
        <span>&#8594;</span>
      {/if}
    </button>
    {#if isSidebarOpen}
      <span class="ml-2 text-black">OPEN EMAIL</span>
    {/if}
  </div>

  {#if isSidebarOpen}
    <div class="p-4 mt-14">
      <ul>
        <li><a href="#" class="block py-2 px-4 hover:bg-gray-200">Home</a></li>
      </ul>
    </div>
  {/if}
</div>

<style>
</style>
