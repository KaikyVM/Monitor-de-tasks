import { useState, useEffect } from "react";

export function useDarkMode(){
    const [darkMode, setDarkMode] = useState(() => {
        const storedDarkMode = localStorage.getItem("darkMode");
        return storedDarkMode ? JSON.parse(storedDarkMode) : false;
      });
    
      useEffect(() => {
        localStorage.setItem("darkMode", JSON.stringify(darkMode));
        document.body.classList.toggle("dark-mode", darkMode);
      }, [darkMode]);

return [darkMode, setDarkMode];
}