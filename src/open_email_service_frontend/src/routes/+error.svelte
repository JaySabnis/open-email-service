
<script>
  export let error;
  export let status=404;
</script>

<svelte:head>
  <title>{status} — Page Not Found</title>
</svelte:head>

<div class="min-h-screen flex items-center justify-center bg-gray-100 text-center px-4">
  <div>
    <h1 class="text-5xl font-bold mb-4">{status}</h1>
    <p class="text-xl mb-8">
      {status === 404
        ? 'Sorry, the page you are looking for does not exist.'
        : error?.message || 'Something went wrong.'}
    </p>
    <a href="/home" class="text-blue-500 underline">Go back to Home</a>
  </div>
</div>
