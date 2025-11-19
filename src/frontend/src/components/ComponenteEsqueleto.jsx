import React from 'react';

const Skeleton = ({ numRows = 5, loading = false }) => {
  if (!loading) return null;

  return (
    <div className="w-full animate-pulse">
      <div className="h-10 bg-gray-200 dark:bg-gray-700 rounded-t-lg mb-4 w-full"></div>
      {[...Array(numRows)].map((_, index) => (
        <div key={index} className="flex items-center space-x-4 mb-4 px-4">
          <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/4"></div>
          <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/6"></div>
          <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/6"></div>
          <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/6"></div>
          <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded w-1/12"></div>
        </div>
      ))}
    </div>
  );
};

export default SkeletonComponent;