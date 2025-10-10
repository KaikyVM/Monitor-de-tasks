import { useState, useEffect } from "react";

export function useTaskFiltering(tasks) {
  const [searchTerm, setSearchTerm] = useState("");
  const [activeCategory, setActiveCategory] = useState("");
  const [activeStatus, setActiveStatus] = useState("");
  
  const [currentPage, setCurrentPage] = useState(1);
  const tasksPerPage = 8;
  
  const filteredTasks = tasks.filter(task => {
    if (!task || !task.TaskIdentifier) {
      return false;
    }

    const taskIdentifierLower = task.TaskIdentifier.toLowerCase();
    const taskStatusLower = (task.Status  || "").toLowerCase();
    const searchTermLower = (searchTerm || "").toLowerCase();
    const activeCategoryLower = (activeCategory || "").toLowerCase();
    const activeStatusLower = (activeStatus || "").toLowerCase();

    // Filtro de Categoria
    const matchesCategory = activeCategoryLower ? taskIdentifierLower.includes(activeCategoryLower) : true;

    // Filtro de Status (na propriedade status)
    const matchesStatus = activeStatusLower ? taskStatusLower === activeStatusLower : true;
    
    // Filtro de Pesquisa (no nome da task)
    const matchesSearch = taskIdentifierLower.includes(searchTermLower);

    // A task só aparece se passar em TODOS os filtros ativos
    return matchesCategory && matchesStatus && matchesSearch;
  });
  
  const indexOfLastTask = currentPage * tasksPerPage;
  const indexOfFirstTask = indexOfLastTask - tasksPerPage;
  const currentTasks = filteredTasks.slice(indexOfFirstTask, indexOfLastTask);
  const totalPages = Math.max(1, Math.ceil(filteredTasks.length / tasksPerPage));
  
  useEffect(() => {
    if (currentPage > totalPages) {
      setCurrentPage(Math.max(1, totalPages));
    }
  }, [currentPage, totalPages, filteredTasks]); // Adicionado filteredTasks como dependência
  
  return {
    searchTerm,
    setSearchTerm,
    currentPage,
    setCurrentPage,
    currentTasks,
    filteredTasks, 
    totalPages,
    indexOfFirstTask,
    activeCategory,
    setActiveCategory,
    activeStatus,
    setActiveStatus,
  };
} 