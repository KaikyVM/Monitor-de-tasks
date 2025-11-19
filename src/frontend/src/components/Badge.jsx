import React from 'react';

const Badge = ({ text, variant = 'informative' }) => {
  const variants = {
    informative: 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300 border border-blue-200 dark:border-blue-800',
    warning: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-300 border border-yellow-200 dark:border-yellow-800',
    positive: 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300 border border-green-200 dark:border-green-800',
    negative: 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300 border border-red-200 dark:border-red-800',
    neutral: 'bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-300 border border-gray-200 dark:border-gray-600',
  };

  // Lógica simples para mapear status do DMS para variantes
  const getVariantFromText = (statusText) => {
    const lower = String(statusText).toLowerCase();
    if (['running', 'available', 'active', 'succeeded', 'replicating'].includes(lower)) return variants.positive;
    if (['failed', 'error'].includes(lower)) return variants.negative;
    if (['stopped', 'ready'].includes(lower)) return variants.neutral;
    if (['creating', 'starting', 'modifying', 'iniciando...', 'executando'].includes(lower)) return variants.warning;
    return variants.neutral;
  };

  const variantClass = variant === 'informative' ? getVariantFromText(text) : variants[variant];
  const baseClass = 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium capitalize';

  return (
    <span className={`${baseClass} ${variantClass}`}>
      {text}
    </span>
  );
};

export default Badge;