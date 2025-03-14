

EVENTHUB_CONNECTION_STR = ""
EVENTHUB_NAME = ""

def on_event(partition_context, event):
    with open('log.json', 'a') as file:
        file.write(event.body_as_str())
    
    # print(f"Received event: {}")

consumer = EventHubConsumerClient.from_connection_string(
    conn_str=EVENTHUB_CONNECTION_STR,
    consumer_group="$Default",
    eventhub_name=EVENTHUB_NAME
)

with consumer:
    consumer.receive(
        on_event=on_event,
        starting_position="-1" # Read all events from the beginning
    )
