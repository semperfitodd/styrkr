import { render, screen } from '@testing-library/react';
import App from './App';

test('renders STYRKR heading', () => {
  render(<App />);
  const headingElement = screen.getByText(/STYRKR/i);
  expect(headingElement).toBeInTheDocument();
});

test('renders tagline', () => {
  render(<App />);
  const taglineElement = screen.getByText(/Your Ultimate Strength Training Companion/i);
  expect(taglineElement).toBeInTheDocument();
});

test('renders author credit', () => {
  render(<App />);
  const authorElement = screen.getByText(/Built with dedication by Todd/i);
  expect(authorElement).toBeInTheDocument();
});
