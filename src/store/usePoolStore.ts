import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { PoolState } from '../types/store';
import { generateId } from '../utils/helpers';

export const usePoolStore = create<PoolState>()(
  persist(
    (set) => ({
      currentDate: new Date(),
      reservations: 0,
      entries: 0,
      entryHistory: [],
      isAffiliatePending: false,
      hasGrantedPermissions: false,
      authorizedCompanions: [],
      affiliates: [],
      pendingRegistrations: [],
      setReservations: (count) => set({ reservations: count }),
      setEntries: (count) => set({ entries: count }),
      setAffiliatePending: (pending) => set({ isAffiliatePending: pending }),
      setPermissionsGranted: (granted) => set({ hasGrantedPermissions: granted }),
      addAffiliate: (affiliate, companions = []) => {
        const affiliateId = generateId();
        const timestamp = new Date().toISOString();

        set((state) => {
          // Create affiliate registration
          const affiliateRegistration = {
            id: affiliateId,
            type: 'affiliate' as const,
            data: affiliate,
            status: 'pending' as const,
            registrationDate: timestamp
          };

          // Create companion registrations
          const companionRegistrations = companions.map(companion => ({
            id: generateId(),
            type: 'companion' as const,
            data: {
              ...companion,
              affiliateId
            },
            status: 'pending' as const,
            registrationDate: timestamp
          }));

          // Add affiliate to affiliates list
          const newAffiliate = {
            ...affiliate,
            id: affiliateId,
            status: 'pending',
            registrationDate: timestamp
          };

          // Add companions to authorized companions list
          const newCompanions = companions.map(companion => ({
            ...companion,
            id: generateId(),
            status: 'pending',
            affiliateId,
            registrationDate: timestamp
          }));

          return {
            affiliates: [...state.affiliates, newAffiliate],
            authorizedCompanions: [...state.authorizedCompanions, ...newCompanions],
            pendingRegistrations: [
              ...state.pendingRegistrations,
              affiliateRegistration,
              ...companionRegistrations
            ],
            isAffiliatePending: true
          };
        });
      },
      updateRegistrationStatus: (id, status) => {
        set((state) => {
          // Find the registration to update
          const registration = state.pendingRegistrations.find(r => r.id === id);
          if (!registration) return state;

          // Update affiliates if it's an affiliate registration
          const updatedAffiliates = state.affiliates.map(affiliate =>
            affiliate.id === id ? { ...affiliate, status } : affiliate
          );

          // Update companions if it's a companion registration
          const updatedCompanions = state.authorizedCompanions.map(companion =>
            companion.id === id ? { ...companion, status } : companion
          );

          // Update the registration in pendingRegistrations
          const updatedRegistrations = state.pendingRegistrations.map(reg =>
            reg.id === id ? { ...reg, status } : reg
          );

          return {
            affiliates: updatedAffiliates,
            authorizedCompanions: updatedCompanions,
            pendingRegistrations: updatedRegistrations,
            isAffiliatePending: registration.type === 'affiliate' ? status === 'pending' : state.isAffiliatePending
          };
        });
      },
      addEntryRecord: (record) => set((state) => ({
        entryHistory: [
          { ...record, timestamp: new Date() },
          ...state.entryHistory
        ],
        entries: state.entries + 1
      }))
    }),
    {
      name: 'pool-store',
    }
  )
);