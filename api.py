from flask import Flask, request, jsonify
from ultralytics import YOLO
import cv2
import numpy as np
from PIL import Image
import io
import base64
from io import BytesIO

# Initialize Flask app
app = Flask(__name__)

# Load the YOLOv8 model
model = YOLO(r"C:\flutterProject\fyp\best.pt")

# API endpoint for processing base64-encoded image
@app.route('/process-image', methods=['POST'])
def process_image():
    try:
        # Get the base64-encoded image from the request
        data = request.get_json()
        base64_image = data['image']

        # Decode the image
        image_data = base64.b64decode(base64_image)
        image = Image.open(BytesIO(image_data)).convert("RGB")  # Ensure the image is in RGB format

        # Convert the PIL image to a NumPy array (YOLO expects NumPy arrays)
        image_np = np.array(image)

        # Perform inference using the YOLOv8 model
        results = model.predict(image_np)

        # Extract detection results
        detections = []
        for result in results[0].boxes.data.tolist():  # Iterate through detected objects
            x1, y1, x2, y2, confidence, class_id = result
            detections.append({
                "class_id": int(class_id),
                "confidence": float(confidence),
                "bounding_box": [x1, y1, x2, y2]
            })

        # Return the detection results as JSON
        return jsonify({"detections": detections}), 200

    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"error": "Failed to process image"}), 500

# Run the Flask app
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
