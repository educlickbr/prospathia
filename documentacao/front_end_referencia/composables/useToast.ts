export function useToast() {
  const ensureContainer = () => {
    let container = document.getElementById("nuxt-toast-container") as
      | HTMLDivElement
      | null;
    if (!container) {
      container = document.createElement("div");
      container.id = "nuxt-toast-container";
      Object.assign(container.style, {
        position: "fixed",
        top: "20px",
        right: "20px",
        zIndex: "9999",
        display: "flex",
        flexDirection: "column",
        gap: "8px",
        alignItems: "flex-end",
        pointerEvents: "none",
      } as Partial<CSSStyleDeclaration>);
      document.body.appendChild(container);
    }
    return container;
  };

  const showToast = (
    message: string,
    opts?: { duration?: number; type?: "info" | "error" | "success" },
  ) => {
    const duration = opts?.duration ?? 5000;
    const type = opts?.type ?? "info";
    const container = ensureContainer();

    const toast = document.createElement("div");
    // toast.textContent = message; // Removing direct text assignment

    Object.assign(toast.style, {
      pointerEvents: "auto",
      background: type === "error"
        ? "#ef4444"
        : type === "success"
        ? "#10b981"
        : "#111827",
      color: "#fff",
      padding: "10px 14px",
      borderRadius: "8px",
      boxShadow: "0 6px 18px rgba(0,0,0,0.12)",
      maxWidth: "340px",
      fontSize: "13px",
      opacity: "0",
      transform: "translateY(-8px)",
      transition: "all 180ms ease",
      display: "flex",
      alignItems: "flex-start",
      gap: "12px",
    } as Partial<CSSStyleDeclaration>);

    // Content Wrapper
    const textSpan = document.createElement("span");
    textSpan.textContent = message;
    textSpan.style.flex = "1";
    textSpan.style.lineHeight = "1.4";

    // Close Button
    const closeBtn = document.createElement("button");
    closeBtn.innerHTML =
      `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>`;
    Object.assign(closeBtn.style, {
      background: "transparent",
      border: "none",
      color: "currentColor",
      opacity: "0.7",
      cursor: "pointer",
      padding: "0",
      marginTop: "2px", // minor visual alignment
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      transition: "opacity 0.2s",
    });

    closeBtn.onmouseenter = () => closeBtn.style.opacity = "1";
    closeBtn.onmouseleave = () => closeBtn.style.opacity = "0.7";

    toast.appendChild(textSpan);
    toast.appendChild(closeBtn);

    container.appendChild(toast);

    // show
    requestAnimationFrame(() => {
      toast.style.opacity = "1";
      toast.style.transform = "translateY(0)";
    });

    const hide = () => {
      toast.style.opacity = "0";
      toast.style.transform = "translateY(-8px)";
      setTimeout(() => {
        if (toast.parentElement) toast.parentElement.removeChild(toast);
      }, 200);
    };

    closeBtn.onclick = (e) => {
      e.stopPropagation(); // prevent other clicks if any
      hide();
    };

    let timer = window.setTimeout(hide, duration);
    toast.addEventListener("mouseenter", () => clearTimeout(timer));
    toast.addEventListener("mouseleave", () => {
      timer = window.setTimeout(hide, (duration / 2) | 0);
    });

    return { hide };
  };

  return { showToast };
}
