import unittest

import handler


class WorkflowAdapterTests(unittest.TestCase):
    def test_maps_public_parameters_and_forces_single_image(self):
        workflow = handler.build_workflow(
            {
                "positive_prompt": "a cinematic portrait",
                "width": 768,
                "height": 1024,
                "seed": 42,
            }
        )
        self.assertEqual(workflow["5"]["inputs"]["text"], "a cinematic portrait")
        self.assertEqual(workflow["7"]["inputs"]["width"], 768)
        self.assertEqual(workflow["7"]["inputs"]["height"], 1024)
        self.assertEqual(workflow["7"]["inputs"]["batch_size"], 1)
        self.assertEqual(workflow["8"]["inputs"]["seed"], 42)

    def test_rejects_invalid_resolution(self):
        with self.assertRaisesRegex(ValueError, "width"):
            handler.build_workflow(
                {"positive_prompt": "test", "width": 1000, "height": 1024}
            )

    def test_rejects_missing_prompt(self):
        with self.assertRaisesRegex(ValueError, "positive_prompt"):
            handler.build_workflow({})


if __name__ == "__main__":
    unittest.main()
