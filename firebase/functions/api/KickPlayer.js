const { onRequest } = require('firebase-functions/v2/https');
const admin = require('../FirebaseAdmin.js');

/**
 * 유저 강퇴 API
 * @param roomNumber - 방 번호
 * @param hostId - 호스트 ID
 * @param playerId - 강퇴할 유저 ID
 * @returns status message
 */
module.exports.kickPlayer = onRequest({ region: 'asia-southeast1' }, async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Only POST requests are accepted' });
  }

  const { roomNumber, hostId, playerId } = req.body;
  if (!roomNumber || !hostId || !playerId) {
    return res.status(400).json({ error: 'Room number, host ID, and player ID are required' });
  }

  try {
    const roomRef = admin.firestore().collection('rooms').doc(roomNumber);
    const roomSnapshot = await roomRef.get();

    if (!roomSnapshot.exists) {
      return res.status(404).json({ error: 'Room not found' });
    }

    const roomData = roomSnapshot.data();

    // 요청한 유저가 방의 호스트인지 확인
    if (roomData.host.id !== hostId) {
      return res.status(403).json({ error: 'Only the host can kick players' });
    }

    const players = roomData.players;
    const playerExists = players.some((player) => player.id === playerId);

    if (!playerExists) {
      return res.status(404).json({ error: 'Player not found in the room' });
    }

    // 강퇴할 플레이어를 players 리스트에서 제거
    const updatedPlayers = players.filter((player) => player.id !== playerId);
    await roomRef.update({
      players: updatedPlayers,
    });

    res.status(200).json({ message: 'Player successfully kicked from the room' });
  } catch (error) {
    console.error('Kick player error:', error);
    res.status(500).json({ error: 'Failed to kick player' });
  }
});
