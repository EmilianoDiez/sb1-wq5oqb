import { supabase } from '../../lib/supabase';
import type { Database } from '../../types/supabase';

type Reservation = Database['public']['Tables']['reservations']['Row'];

export const createReservation = async (
  userId: string,
  date: string,
  companionIds: string[]
): Promise<{ id: string }> => {
  try {
    const { data, error } = await supabase
      .rpc('create_reservation', {
        user_id_param: userId,
        date_param: date,
        companion_ids: companionIds
      });

    if (error) {
      console.error('Error creating reservation:', error);
      throw new Error(error.message);
    }

    return { id: data };
  } catch (error) {
    console.error('Error in createReservation:', error);
    throw error;
  }
};

export const getReservationsByUserId = async (userId: string): Promise<Reservation[]> => {
  try {
    const { data, error } = await supabase
      .from('reservations')
      .select(`
        *,
        companions:reservation_companions(
          companion:companions(*)
        )
      `)
      .eq('user_id', userId)
      .order('date', { ascending: true });

    if (error) {
      console.error('Error fetching reservations:', error);
      throw error;
    }

    return data || [];
  } catch (error) {
    console.error('Error in getReservationsByUserId:', error);
    throw error;
  }
};

export const cancelReservation = async (id: string): Promise<void> => {
  try {
    const { error } = await supabase
      .from('reservations')
      .update({ status: 'cancelled' })
      .eq('id', id);

    if (error) {
      console.error('Error cancelling reservation:', error);
      throw error;
    }
  } catch (error) {
    console.error('Error in cancelReservation:', error);
    throw error;
  }
};