import React from 'react';
import { ArrowRight, Users, Calendar, QrCodeIcon } from 'lucide-react';
import { Link } from 'react-router-dom';
import DailyStats from '../components/DailyStats';
import PendingApproval from '../components/PendingApproval';
import PricingDisplay from '../components/pricing/PricingDisplay';
import { usePoolStore } from '../store/usePoolStore';

const Home = () => {
  const { isAffiliatePending } = usePoolStore();

  return (
    <div className="max-w-7xl mx-auto">
      <div className="text-center mb-8">
        <h1 className="text-2xl font-bold text-gray-900 mb-4">
          Reservas e ingresos de FADIUNC y El Olmo
        </h1>
        <p className="text-lg text-gray-600 max-w-2xl mx-auto">
          Para afiliados y afiliadas de FADIUNC
        </p>
      
        <h1 className="text-lg font-bold text-gray-900 mb-4">
         El beneficio es por orden de llegada, con cupo para bonificación al 100% y al 50%.
        </h1>
        </div>
      
      <DailyStats />

      {isAffiliatePending && (
        <div className="mb-12">
          <PendingApproval />
        </div>
      )}

      <div className="grid md:grid-cols-3 gap-8 mb-16">
        <div className="bg-white rounded-xl shadow-md p-6 hover:shadow-lg transition-shadow">
          <Users className="w-12 h-12 text-blue-600 mb-4" />
          <h3 className="text-xl font-semibold mb-2">Registro de Afiliados</h3>
          <p className="text-gray-600 mb-4">
            Registro para afiliados/as y acompañantes para acceder a los beneficios
          </p>
          <Link
            to="/register"
            className="inline-flex items-center text-blue-600 hover:text-blue-700"
          >
            Registrarse ahora <ArrowRight className="ml-2 w-4 h-4" />
          </Link>
        </div>

        <div className="bg-white rounded-xl shadow-md p-6 hover:shadow-lg transition-shadow">
          <Calendar className="w-12 h-12 text-blue-600 mb-4" />
          <h3 className="text-xl font-semibold mb-2">Reservas</h3>
          <p className="text-gray-600 mb-4">
            Reservá tu lugar y el de tus acompañantes de manera fácil y rápida
          </p>
          <Link
            to="/reservations"
            className="inline-flex items-center text-blue-600 hover:text-blue-700"
          >
            Hacer una reserva <ArrowRight className="ml-2 w-4 h-4" />
          </Link>
        </div>

        <div className="bg-white rounded-xl shadow-md p-6 hover:shadow-lg transition-shadow">
          <QrCodeIcon className="w-12 h-12 text-blue-600 mb-4" />
          <h3 className="text-xl font-semibold mb-2">Escáner QR</h3>
          <p className="text-gray-600 mb-4">
            Escaneá tu código QR al ingresar y conocé el estado de ocupación en tiempo real
          </p>
          <Link
            to="/scanner"
            className="inline-flex items-center text-blue-600 hover:text-blue-700"
          >
            Ir al escáner <ArrowRight className="ml-2 w-4 h-4" />
          </Link>
        </div>
      </div>

      <div className="mb-16">
        <PricingDisplay />
      </div>
    </div>
  );
};

export default Home;