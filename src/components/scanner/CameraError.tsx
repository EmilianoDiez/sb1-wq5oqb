import React from 'react';
import { Camera, AlertCircle, Settings } from 'lucide-react';

interface CameraErrorProps {
  error: string;
  onRetry: () => void;
}

export const CameraError: React.FC<CameraErrorProps> = ({ error, onRetry }) => {
  const openSettings = () => {
    if ('mediaDevices' in navigator) {
      window.open('app-settings:', '_blank');
    }
  };

  return (
    <div className="bg-red-50 border border-red-200 rounded-lg p-6">
      <div className="flex items-start space-x-3">
        <AlertCircle className="w-6 h-6 text-red-600 mt-1" />
        <div className="flex-1">
          <h3 className="text-lg font-medium text-red-800">
            Problema con la cámara
          </h3>
          <p className="mt-2 text-sm text-red-700">{error}</p>
          
          <div className="mt-4 flex flex-wrap gap-4">
            <button
              onClick={onRetry}
              className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
            >
              <Camera className="w-4 h-4 mr-2" />
              Reintentar
            </button>
            
            <button
              onClick={openSettings}
              className="inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
            >
              <Settings className="w-4 h-4 mr-2" />
              Abrir configuración
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CameraError;