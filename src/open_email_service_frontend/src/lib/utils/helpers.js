  export function uint8ArrayToBase64(bytes) {
    const binary = Array.from(bytes)
      .map((byte) => String.fromCharCode(byte))
      .join("");
    return btoa(binary);
  }

  export function generateImageSrc(blob) {
  // console.log("generateImageSrc", blob);
  let byteArray;

  if (blob instanceof Uint8Array) {
    byteArray = blob;
  } else if (Array.isArray(blob) && blob[0] instanceof Uint8Array) {
    byteArray = blob[0];
  } else if (blob && typeof blob === "object" && !Array.isArray(blob)) {
    const values = Object.values(blob);
    if (values.length > 0) {
      byteArray = Uint8Array.from(values);
    }
  } else if (typeof blob === "string") {
    if (blob.startsWith("data:image")) {
      return blob;
    }
    if (blob.trim() !== "") {
      return `data:image/png;base64,${blob}`;
    }
  }

  if (byteArray) {
    return `data:image/png;base64,${uint8ArrayToBase64(byteArray)}`;
  }

  return "/user1.png";
}

