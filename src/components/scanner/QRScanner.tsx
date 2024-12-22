import React, { useEffect, useState } from 'react';
import { Html5QrcodeScanner } from 'html5-qrcode';
import { usePoolStore } from '../../store/usePoolStore';
import { validateEntry } from '../../utils/qr/validation';
import { calculatePrice } from '../../utils/pricing';
import { getQRScannerConfig } from '../../utils/scanner/qrConfig';
import { diagnoseCameraError } from '../../utils/scanner/diagnostics';
import { useCamera } from '../../hooks/useCamera';
import { ScanResult } from './ScanResult';
import { CameraButton } from './CameraButton';
import { CameraError } from './CameraError';

export const QRScanner: React.FC = () => {
  const [scanner, setScanner] = useState<Html5QrcodeScanner | null>(null);
  const [result, setResult] = useState<{
    status: 'success' | 'error';
    message: string;
    details?: {
      name: string;
      dni: string;
      type: 'affiliate' | 'companion';
      price: number;
      discount: number;
    };
  } | null>(null);

  const { addEntryRecord, entryHistory } = usePoolStore();
  const { isLoading, hasPermission, error, initializeCamera, resetError } = useCamera();

  useEffect(() => {
    if (hasPermission) {
      const config = getQRScannerConfig();
      const newScanner = new Html5QrcodeScanner('qr-reader', config, false);
      
      newScanner.render(
        async (decodedText) => {
          try {
            const dni = prompt('Por favor, ingrese su DNI:');
            if (!dni) {
              setResult({
                status: 'error',
                message: 'DNI requerido para validar el ingreso'
              });
              return;
            }

            const validation = await validateEntry(decodedText, dni);
            
            if (!validation.isValid || !validation.details) {
              setResult({
                status: 'error',
                message: validation.message
              });
              return;
            }

            const todayEntries = entryHistory.filter(
              entry => entry.timestamp.toDateString() === new Date().toDateString()
            );

            const pricing = calculatePrice({
              type: validation.details.type,
              currentAffiliates: todayEntries.filter(e => e.type === 'affiliate').length,
              currentCompanions: todayEntries.filter(e => e.type === 'companion').length
            });

            addEntryRecord({
              name: validation.details.name,
              dni: validation.details.dni,
              type: validation.details.type,
              qrCode: decodedText,
              timestamp: new Date()
            });

            setResult({
              status: 'success',
              message: 'Ingreso registrado exitosamente',
              details: {
                ...validation.details,
                price: pricing.price,
                discount: pricing.discount
              }
            });
          } catch (error) {
            console.error('Error processing scan:', error);
            setResult({
              status: 'error',
              message: 'Error al procesar el código QR'
            });
          }
        },
        (error) => {
          const errorMessage = diagnoseCameraError(error);
          console.error('QR Scan error:', errorMessage);
        }
      );
      
      setScanner(newScanner);

      return () => {
        if (newScanner) {
          newScanner.clear().catch(console.error);
        }
      };
    }
  }, [hasPermission, addEntryRecord, entryHistory]);

  const handleRetry = () => {
    resetError();
    initializeCamera();
  };

  return (
    <div className="space-y-6">
      {!hasPermission && !error && (
        <div className="flex justify-center">
          <CameraButton
            onClick={initializeCamera}
            isLoading={isLoading}
            disabled={hasPermission}
          />
        </div>
      )}

      {error && (
        <CameraError 
          error={error}
          onRetry={handleRetry}
        />
      )}

      <div id="qr-reader" className={`mx-auto max-w-lg ${!hasPermission ? 'hidden' : ''}`}></div>
      
      {result && (
        <ScanResult
          {...result}
          onClose={() => setResult(null)}
        />
      )}
    </div>
  );
};

export default QRScanner;