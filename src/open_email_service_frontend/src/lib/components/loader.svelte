<script>
    export let message = "Loading...";
    export let fullScreen = true;
  </script>
  
  <div class={`flex items-center justify-center ${fullScreen ? 'h-screen' : 'h-full'} bg-gray-50`}>
    <div class="flex flex-col items-center space-y-4">
      <div class="w-16 h-16 border-4 border-blue-500 border-t-transparent rounded-full animate-spin"></div>
      <p class="text-blue-600 font-medium text-lg animate-pulse">{message}</p>
    </div>
  </div>
  