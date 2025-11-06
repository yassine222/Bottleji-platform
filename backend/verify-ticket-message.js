// Script to verify the initial message was added to support ticket
const { MongoClient, ObjectId } = require('mongodb');

const uri = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji?retryWrites=true&w=majority';
const dbName = 'bottleji';

async function verifyMessage() {
  const client = new MongoClient(uri);

  try {
    await client.connect();
    console.log('Connected to MongoDB');

    const db = client.db(dbName);
    const ticketsCollection = db.collection('supporttickets');

    const ticketId = '68f57656644889536cf60e5c';

    // Get the ticket
    const ticket = await ticketsCollection.findOne({ _id: new ObjectId(ticketId) });

    if (!ticket) {
      console.log('❌ Ticket not found');
      return;
    }

    console.log('📋 Ticket:', ticket.title);
    console.log('📝 Messages count:', ticket.messages ? ticket.messages.length : 0);
    
    if (ticket.messages && ticket.messages.length > 0) {
      console.log('\n📨 Messages:');
      ticket.messages.forEach((msg, index) => {
        console.log(`\nMessage ${index + 1}:`);
        console.log('  Message:', msg.message);
        console.log('  Sender ID:', msg.senderId);
        console.log('  Sender Type:', msg.senderType);
        console.log('  Sent At:', msg.sentAt);
        console.log('  Is Internal:', msg.isInternal);
      });
    } else {
      console.log('⚠️ No messages found');
    }

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await client.close();
    console.log('\nDisconnected from MongoDB');
  }
}

verifyMessage();

