// Script to add initial message to support ticket document
// Ticket ID: 68f57656644889536cf60e5c

const { MongoClient, ObjectId } = require('mongodb');

const uri = 'mongodb+srv://yassineromd789:GOj2qBAwhlsY4j0K@cluster0.ailekkg.mongodb.net/bottleji?retryWrites=true&w=majority';
const dbName = 'bottleji';

async function addInitialMessage() {
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

    console.log('📋 Found ticket:', ticket.title);
    console.log('📝 Description:', ticket.description);
    console.log('👤 User ID:', ticket.userId);
    console.log('📦 Related Drop ID:', ticket.relatedDropId);
    console.log('🚛 Related Collection ID:', ticket.relatedCollectionId);
    console.log('📅 Created At:', ticket.createdAt);

    // Check if messages array is empty
    if (ticket.messages && ticket.messages.length > 0) {
      console.log('⚠️ Ticket already has messages. Skipping...');
      return;
    }

    // Format the initial message
    let messageText = ticket.description || '';

    // Add Drop reference if exists
    if (ticket.relatedDropId) {
      const dropId = ticket.relatedDropId.toString();
      // Extract last 8 characters for display
      const shortDropId = dropId.slice(-8);
      messageText += `\n📦 Related to Drop: ${shortDropId}...`;
    }

    // Add Collection reference if exists
    if (ticket.relatedCollectionId) {
      const collectionId = ticket.relatedCollectionId.toString();
      // Extract last 8 characters for display
      const shortCollectionId = collectionId.slice(-8);
      messageText += `\n🚛 Related to Collection: ${shortCollectionId}...`;
    }

    // Create the initial message object
    // Ensure senderId is an ObjectId (it might already be one, but ensure it)
    const senderId = ticket.userId instanceof ObjectId ? ticket.userId : new ObjectId(ticket.userId);
    
    const initialMessage = {
      message: messageText,
      senderId: senderId,
      senderType: 'user',
      sentAt: ticket.createdAt || new Date(),
      isInternal: false
    };

    console.log('📨 Creating initial message:');
    console.log(JSON.stringify(initialMessage, null, 2));

    // Update the ticket with the initial message
    const result = await ticketsCollection.updateOne(
      { _id: new ObjectId(ticketId) },
      {
        $push: {
          messages: initialMessage
        }
      }
    );

    if (result.modifiedCount > 0) {
      console.log('✅ Successfully added initial message to ticket');
    } else {
      console.log('❌ Failed to update ticket');
    }

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await client.close();
    console.log('Disconnected from MongoDB');
  }
}

addInitialMessage();

